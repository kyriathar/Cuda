#include <stdio.h>
#include <stdlib.h>

#include <unistd.h>

#include "filterise.h"

#define BLOCKS 5040

#define THREADS_PER_BLOCK 960

__global__ void filterise(int * filter,unsigned char * image_in_d ,unsigned char * image_out_d){
	int x=0 ;
    	int y=0 ;
    	int new_x =0;
    	int new_y =0;
    	int fx=0 ,fy=0 ;
    	int sum=0 ;			
	
	int i = blockIdx.x * blockDim.x + threadIdx.x;     
	
	x= blockIdx.x * blockDim.x;
	y= threadIdx.x;	

	if(i<IMAGE_SIZE){
		
		sum = 0 ;
		for(fx=-1;fx<=1;fx++)
		{
			if( blockIdx.x-fx < 0 ) {  
				//block 0
				new_x = 5038 * blockDim.x ;			
			}
			else if( blockIdx.x-fx == 0 ) {  
				//block 1			
				new_x = 5039 * blockDim.x ;
			}
			else if(blockIdx.x-fx == 5039) { 
				new_x = 0 * blockDim.x ; 
			}
			else if(blockIdx.x-fx == 5040) { 
				new_x = 1 * blockDim.x ; 
			}
			else {
				new_x = x -fx* blockDim.x*2 ;
			}
			
			for(fy=-1;fy<=1;fy++)
			{    
				if(y-fy < 0){
					if(blockIdx.x%2 == 0){
						new_y = 959;
						new_x += blockDim.x;					
					}
					if(blockIdx.x%2 == 1){
						new_y = y-fy;					
					} 				
				}
				else if(y-fy == 960) {
					if(blockIdx.x%2 == 0){
						new_y = y-fy;					
					}
					if(blockIdx.x%2 == 1){
						new_y = 0 ;
						new_x -=blockDim.x ;					
					}
				}
				else{
					new_y = y -fy ;
				}

				sum += image_in_d[new_x+new_y]*filter[(fx+1)*3+(fy+1)];
			}
		}
		image_out_d[x + y] = (int)sum/16 ;
	}
	__syncthreads();		
}



void filterise_wrapper(int * filter,unsigned char * image_in_d ,unsigned char * image_out_d,unsigned char * image_in ,unsigned char * image_out){
        int i ;
        unsigned char * temp = NULL;
	
    
	

        //dim3 dimBl(BLOCK_SIZE);  
	//dim3 dimGr(HEIGHT); 
        
        for(i=0;i<1000;i++){
	    filterise<<< BLOCKS , THREADS_PER_BLOCK>>>(filter,image_in_d ,image_out_d );
	
	    temp = image_in_d ;
            image_in_d = image_out_d ;
            image_out_d = temp ;

	}
	
}
