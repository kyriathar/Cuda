#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <unistd.h>

#include "filterise.h"
#include "my_functions.h"
//#include "reduce.h"

int main(int argc, char** argv) {
    
    int i=0 ;
    //int keep_going =1;
    unsigned char k ;
    unsigned char * image_in = NULL ;
    unsigned char * image_out = NULL ;
    int * cpu_filter = NULL ;
    FILE * oldfile = NULL;
    FILE * newfile = NULL;
    
    //Arrays for Cuda
    unsigned char * image_in_d = NULL ;
    unsigned char * image_out_d = NULL ;
    int * gpu_filter = NULL ;
    
    time_t start_t, end_t;
    double diff_t;
    
    oldfile = fopen("waterfall_grey_1920_2520.raw","r");
    newfile = fopen("out.raw","w");
    
    if(oldfile == NULL){
        printf("ERROR @ fopen : oldfile\n");
        return(EXIT_FAILURE);
    }
    
    if(newfile == NULL){
        printf("ERROR @ fopen : newfile\n");
        return(EXIT_FAILURE);
    }
    
    /*allocate pixel arrays*/
    image_in =(unsigned char *)my_malloc(IMAGE_SIZE * sizeof(unsigned char)); 
    image_out =(unsigned char *)my_malloc(IMAGE_SIZE * sizeof(unsigned char));
    
    /*Create filter*/
    cpu_filter = (int *)my_malloc(9*sizeof(int));
    cpu_filter[0]= 1;
    cpu_filter[1]= 2;
    cpu_filter[2]= 1;
    cpu_filter[3]= 2;
    cpu_filter[4]= 4;
    cpu_filter[5]= 2;
    cpu_filter[6]= 1;
    cpu_filter[7]= 2;
    cpu_filter[8]= 1;
    
    
    /*allocate memory Cuda...*/
    cudaMalloc((void **)&image_in_d, IMAGE_SIZE * sizeof(unsigned char) );
    cudaMalloc((void **)&image_out_d, IMAGE_SIZE * sizeof(unsigned char) );
    cudaMalloc((void **)&gpu_filter, 9 * sizeof(int) );
    
    /*initialise pixel arrays*/
    for(i =0;i<IMAGE_SIZE;i++){
        image_in[i]  = 0;
        image_out[i] = 0;
    }
    
    /*passing from file to pixel array*/
    i=0;
    
    while( fread(&k,1,1,oldfile)>0){     
        image_in[i] = k;
        i++;
    }
    
    /*Copy arrays to GPU*/
    cudaMemcpy(image_in_d, image_in, IMAGE_SIZE * sizeof(unsigned char), cudaMemcpyHostToDevice) ;
    cudaMemset(image_out_d, 255, IMAGE_SIZE * sizeof(unsigned char)) ;
    cudaMemcpy(gpu_filter, cpu_filter, 9 * sizeof(int), cudaMemcpyHostToDevice) ;
    
    

    /*filterize*/
    time(&start_t);
    
    
        
	filterise_wrapper(gpu_filter,image_in_d ,image_out_d,image_in,image_out);
	/*keep_going = check_convergence(image_in,image_out);
	/*if(!keep_going)
	{
	    printf("Epanalipseis  = %d \n",w);
	    break;
	}*/
    
    
    time(&end_t);
    
    /*write to new file*/
    cudaMemcpy(image_in, image_in_d, IMAGE_SIZE * sizeof(unsigned char), cudaMemcpyDeviceToHost) ;
    fwrite(image_in,sizeof(unsigned char),IMAGE_SIZE,newfile);
    
    diff_t = difftime(end_t, start_t);
    printf("Execution time = %f seconds\n", diff_t);
    
    /*final actions*/
    
    fclose (oldfile);
    fclose (newfile);
    
    free(image_in);
    free(image_out);

    cudaFree(image_in_d);
    cudaFree(image_out_d);
    cudaFree(gpu_filter);
    
    
    return (EXIT_SUCCESS);
}
