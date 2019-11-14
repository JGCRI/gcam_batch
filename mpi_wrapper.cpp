#include <iostream>
#include <stdlib.h>
#include <string>
#include <sstream>

// To compile: mpicxx -DMPICH_IGNORE_CXX_SEEK -lpmi -o mpi_wrapper.exe mpi_wrapper.cpp
using namespace std;

#include "mpi.h"

int main (int argc, char * argv[]) {
 
    if (argc != 3) {	// we are expecting (i) base config file name and (ii) base task number
	cout << "Incorrect number of arguments - " << argc << endl;
	return 1;
    }
    
    int base_id = argc ? atoi( argv[2] ) : 0;
     
    // cout << "Here we are!" << endl;

    MPI::Init( argc, argv );
    
    // cout << "Init'ed OK" << endl;

    int id = MPI::COMM_WORLD.Get_rank();

    // cout << "Got rank OK" << endl;
    
    int final_id = id + base_id;
    //cout << final_id << endl;
    
    stringstream command2;
    command2 << "bash run_model.sh " << argv[1] << " " << final_id;

    cout << "About to run: " << command2.str() << endl;
   
    int result = system(command2.str().c_str());

    MPI::Finalize();
    
    return result;
}

