#import <unistd.h>
#import <errno.h>
#import <sys/sysctl.h>
#import <stdlib.h>
#import <Foundation/Foundation.h>

enum	{kSuccess = 0,
        kCouldNotFindRequestedProcess = -1, 
        kInvalidArgumentsError = -2,
        kErrorGettingSizeOfBufferRequired = -3,
        kUnableToAllocateMemoryForBuffer = -4,
        kPIDBufferOverrunError = -5};

int getInfoForAllProcesses(struct kinfo_proc **processInfo,
                             unsigned long *NumberOfRunningProcesses,
                             int *SysctlError);

// Returns an array of pids for all the processes whose name matches targetName
NSSet * getAllPIDsForProcessName(const char *targetName)
{
	struct kinfo_proc *allProcessesInfo;
	unsigned long numProcesses, i;
	int error;
    NSMutableSet *result = [NSMutableSet set];
	
	error = getInfoForAllProcesses(&allProcessesInfo, &numProcesses, NULL);
	
	if (error != 0 || numProcesses == 0) {
        return result;
    }
	
	for(i = 0; i < numProcesses; ++i) {
        pid_t currentPid = allProcessesInfo[i].kp_proc.p_pid; 
        const char *currentName = allProcessesInfo[i].kp_proc.p_comm; 
        
        if (currentPid > 0 && strncmp(currentName, targetName, MAXCOMLEN) == 0) {
            [result addObject:@(currentPid)];
        }
    }
	
    free(allProcessesInfo);
    return result;
}

// Returns an array of pids for all the processes whose name matches targetName and whose real uid matches targetUid
NSSet * getAllPIDsForProcessNameRunByUser(const char *targetName, uid_t targetUid)
{
	struct kinfo_proc *allProcessesInfo = NULL;
	unsigned long numProcesses, i;
    int error;
    NSMutableSet *result = [NSMutableSet set];
	
	error = getInfoForAllProcesses(&allProcessesInfo, &numProcesses, NULL);
	
	if (error != 0 || numProcesses == 0) {
        if (allProcessesInfo) {
            free(allProcessesInfo);
        }
        
        return result;
    }
	
	for(i = 0; i < numProcesses; ++i) {
		pid_t currentPid = allProcessesInfo[i].kp_proc.p_pid; 
        uid_t currentUid = allProcessesInfo[i].kp_eproc.e_pcred.p_ruid; 
        const char *currentName = allProcessesInfo[i].kp_proc.p_comm; 
        
        if (currentPid > 0 && currentUid == targetUid && strncmp(currentName, targetName, MAXCOMLEN) == 0) {
            [result addObject:@(currentPid)];
        }
    }
	
    free(allProcessesInfo);
    return result;
}


// The original version of this function was borrowed from the example code GetPID from
// Apple, written by Chad Jones. This version has been modified to return an array of
// structures containing current process information.
int getInfoForAllProcesses(struct kinfo_proc **processInfo,
                             unsigned long *NumberOfRunningProcesses,
                             int *SysctlError)
{
    // --- Defining local variables for this function and initializing all to zero --- //
    int mib[6] = {0,0,0,0,0,0}; //used for sysctl call.
    int SuccessfullyGotProcessInformation;
    size_t sizeOfBufferRequired = 0; //set to zero to start with.
    int error = 0;
    struct kinfo_proc* BSDProcessInformationStructure = NULL;

    // --- Checking input arguments for validity --- //
    if (processInfo == NULL)
    {
        return(kInvalidArgumentsError);
    }

    if (NumberOfRunningProcesses == NULL)
    {
        return(kInvalidArgumentsError);
    }

    //--- Setting return values to known values --- //

    if (SysctlError != NULL) //only set sysctlError if it is present
    {
        *SysctlError = 0;
    }

    //--- Getting list of process information for all processes --- //
    
    /* Setting up the mib (Management Information Base) which is an array of integers where each
    * integer specifies how the data will be gathered.  Here we are setting the MIB
    * block to lookup the information on all the BSD processes on the system.  Also note that
    * every regular application has a recognized BSD process accociated with it.  We pass
    * CTL_KERN, KERN_PROC, KERN_PROC_ALL to sysctl as the MIB to get back a BSD structure with
    * all BSD process information for all processes in it (including BSD process names)
    */
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_ALL;

    /* Here we have a loop set up where we keep calling sysctl until we finally get an unrecoverable error
    * (and we return) or we finally get a succesful result.  Note with how dynamic the process list can
    * be you can expect to have a failure here and there since the process list can change between
    * getting the size of buffer required and the actually filling that buffer.
    */
    SuccessfullyGotProcessInformation = FALSE;
    
    while (SuccessfullyGotProcessInformation == FALSE)
    {
        /* Now that we have the MIB for looking up process information we will pass it to sysctl to get the 
        * information we want on BSD processes.  However, before we do this we must know the size of the buffer to 
        * allocate to accomidate the return value.  We can get the size of the data to allocate also using the 
        * sysctl command.  In this case we call sysctl with the proper arguments but specify no return buffer 
        * specified (null buffer).  This is a special case which causes sysctl to return the size of buffer required.
        *
        * First Argument: The MIB which is really just an array of integers.  Each integer is a constant
        *     representing what information to gather from the system.  Check out the man page to know what
        *     constants sysctl will work with.  Here of course we pass our MIB block which was passed to us.
        * Second Argument: The number of constants in the MIB (array of integers).  In this case there are three.
        * Third Argument: The output buffer where the return value from sysctl will be stored.  In this case
        *     we don't want anything return yet since we don't yet know the size of buffer needed.  Thus we will
        *     pass null for the buffer to begin with.
        * Forth Argument: The size of the output buffer required.  Since the buffer itself is null we can just
        *     get the buffer size needed back from this call.
        * Fifth Argument: The new value we want the system data to have.  Here we don't want to set any system
        *     information we only want to gather it.  Thus, we pass null as the buffer so sysctl knows that 
        *     we have no desire to set the value.
        * Sixth Argument: The length of the buffer containing new information (argument five).  In this case
        *     argument five was null since we didn't want to set the system value.  Thus, the size of the buffer
        *     is zero or NULL.
        * Return Value: a return value indicating success or failure.  Actually, sysctl will either return
        *     zero on no error and -1 on error.  The errno UNIX variable will be set on error.
        */ 
        error = sysctl(mib, 3, NULL, &sizeOfBufferRequired, NULL, (size_t)NULL);

        /* If an error occurred then return the accociated error.  The error itself actually is stored in the UNIX 
        * errno variable.  We can access the errno value using the errno global variable.  We will return the 
        * errno value as the sysctlError return value from this function.
        */
        if (error != 0) 
        {
            if (SysctlError != NULL)
            {
                *SysctlError = errno;  //we only set this variable if the pre-allocated variable is given
            } 

            return(kErrorGettingSizeOfBufferRequired);
        }
    
        /* Now we successful obtained the size of the buffer required for the sysctl call.  This is stored in the 
        * SizeOfBufferRequired variable.  We will malloc a buffer of that size to hold the sysctl result.
        */
        BSDProcessInformationStructure = (struct kinfo_proc*) malloc(sizeOfBufferRequired);

        if (BSDProcessInformationStructure == NULL)
        {
            if (SysctlError != NULL)
            {
                *SysctlError = ENOMEM;  //we only set this variable if the pre-allocated variable is given
            } 

            return(kUnableToAllocateMemoryForBuffer); //unrecoverable error (no memory available) so give up
        }
    
        /* Now we have the buffer of the correct size to hold the result we can now call sysctl
        * and get the process information.  
        *
        * First Argument: The MIB for gathering information on running BSD processes.  The MIB is really 
        *     just an array of integers.  Each integer is a constant representing what information to 
        *     gather from the system.  Check out the man page to know what constants sysctl will work with.  
        * Second Argument: The number of constants in the MIB (array of integers).  In this case there are three.
        * Third Argument: The output buffer where the return value from sysctl will be stored.  This is the buffer
        *     which we allocated specifically for this purpose.  
        * Forth Argument: The size of the output buffer (argument three).  In this case its the size of the 
        *     buffer we already allocated.  
        * Fifth Argument: The buffer containing the value to set the system value to.  In this case we don't
        *     want to set any system information we only want to gather it.  Thus, we pass null as the buffer
        *     so sysctl knows that we have no desire to set the value.
        * Sixth Argument: The length of the buffer containing new information (argument five).  In this case
        *     argument five was null since we didn't want to set the system value.  Thus, the size of the buffer
        *     is zero or NULL.
        * Return Value: a return value indicating success or failure.  Actually, sysctl will either return 
        *     zero on no error and -1 on error.  The errno UNIX variable will be set on error.
        */ 
        error = sysctl(mib, 3, BSDProcessInformationStructure, &sizeOfBufferRequired, NULL, (size_t)NULL);
    
        //Here we successfully got the process information.  Thus set the variable to end this sysctl calling loop
        if (error == 0)
        {
            SuccessfullyGotProcessInformation = TRUE;
        }
        else 
        {
            /* failed getting process information we will try again next time around the loop.  Note this is caused
            * by the fact the process list changed between getting the size of the buffer and actually filling
            * the buffer (something which will happen from time to time since the process list is dynamic).
            * Anyways, the attempted sysctl call failed.  We will now begin again by freeing up the allocated 
            * buffer and starting again at the beginning of the loop.
            */
            free(BSDProcessInformationStructure); 
        }
    }//end while loop

    // --- Going through process list looking for processes with matching names --- //

    /* Now that we have the BSD structure describing the running processes we will parse it for the desired
     * process name.  First we will the number of running processes.  We can determine
     * the number of processes running because there is a kinfo_proc structure for each process.
     */
    (*NumberOfRunningProcesses) = sizeOfBufferRequired / sizeof(struct kinfo_proc);  
    
	(*processInfo) = BSDProcessInformationStructure;
	
	return(kSuccess);
}
