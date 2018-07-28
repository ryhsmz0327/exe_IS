#include <stdio.h>
#include <ctype.h> // isalnum()
#include <string.h> // stricmp()
#include <stdlib.h> // exit()
#include <sys/time.h>
#define N 26
#define BLOCK 32
#define LINE_SIZE 1024

__global__ void countAlphaOnGPU (char *idata, int *sum, int size) {
  int idx = blockIdx.x * blockDim.x + threadIdx.x;

  // printf("%d", ('a'-'A'));
  // printf("%c", idata[idx]);
  // printf("%d ", idata[idx]-'a');
  // printf("%d ", ('a'-'A'));
  // sum[idata[idx]-'a'] += 1;
  // printf("%d ", sum[idata[idx]-'a']);
  // printf("%d ", sum[idx]);


    // if ((idata[idx] >= 'A') && (idata[idx] <= 'Z')) {
    //   atomicAdd(&sum[idata[idx]-'A'],1);
    // } else if ((idata[idx] >= 'a') && (idata[idx] <= 'z')) {
    //   atomicAdd(&sum[idata[idx]-'a'],1);
    // }
  
  for (int i = 0; i < size; i++) {
    if ((idata[size*idx+i] >= 'A') && (idata[size*idx+i] <= 'Z')) {
      atomicAdd(&sum[idata[size*idx+i]-'A'],1);
    } else if ((idata[size*idx+i] >= 'a') && (idata[size*idx+i] <= 'z')) {
      atomicAdd(&sum[idata[size*idx+i]-'a'],1);
    }
  }

}
/*
__global__ void reduction0(int *idata, int *sum) {
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  atomicAdd(sum,idata[idx]);
}

void init(int *idata) {
  for (int i = 0; i < N; i++) {
    idata[i] = 1;
  }
}
*/

double cpuSecond() {
  struct timeval tp;
  gettimeofday(&tp, NULL);
  return ((double)tp.tv_sec + (double)tp.tv_usec*1.e-6);
}


int main(void){
  FILE *fp;
  char *fp2, *idata;
  int *odata, *sum; 
  long sz;
  char *fp3;

  double iStart_cpu, iElaps_cpu;
  double iStart_cpu2, iElaps_cpu2;
  double iStart_cpu3, iElaps_cpu3;

  double iStart_cpu4, iElaps_cpu4, iStart_cpu5, iElaps_cpu5;

  iStart_cpu = cpuSecond();

	if ( (fp=fopen("book4.txt","r"))==NULL ) {
		printf("File not open...\n");
		exit(1);
  }

  // fseek(fp, 0, SEEK_SET);
  // // printf("%c", fp->_IO_read_ptr[0]);
  // for (int j = 0; j < 1000; j++) {
  //   printf("%c", fp->_IO_read_ptr[j]);
  // }
  

  fseek(fp, 0, SEEK_END);
  sz = ftell(fp);
  printf("ファイルのサイズ : %ldバイト\n", sz);
  fseek(fp, 0, SEEK_SET);

  // for (int j = 0; j < 1000; j++) {
  //   printf("%c", fp->_IO_read_ptr[j]);
  // }
  // printf("\n");

  fp2 = (char *)malloc(sz);
  // fp2 = (char *)malloc(1024*sizeof(char));
  // fp3 = (char *)malloc(sz);
  iStart_cpu4 = cpuSecond();
  int z = 0;
  while ((fp2[z] = fgetc(fp)) != EOF) { // ラインでとる or 全て一気にとる方法を考える
      z++;
  }
  iElaps_cpu4 = cpuSecond() - iStart_cpu4;

  iStart_cpu5 = cpuSecond();
  // while ( fgets(fp2, 1024, fp) != NULL ) {
  //   strcat(fp3,fp2);
  //   // for (int i = 0; fp2[i] != '\0'; i++)
  //   //   printf("%c", fp2[i]);
  // }
  iElaps_cpu5 = cpuSecond() - iStart_cpu5;
  // for (int i = 0; fp3[i] != '\0'; i++) {
  //   printf("%c", fp3[i]);
  // }

  fseek(fp, 0, SEEK_SET);

  iStart_cpu3 = cpuSecond();
  cudaMalloc((void**)&idata, sz);
  cudaMalloc((void**)&odata, N*sizeof(int));
  iElaps_cpu3 = cpuSecond() - iStart_cpu3;
  // // host_idata = (char *)malloc(N*sizeof(char));
  sum = (int *)malloc(N*sizeof(int));
  // init(host_idata);
  
  // cudaMemcpy(idata, fp2, sz, cudaMemcpyHostToDevice);
  cudaMemcpy(idata, fp2, sz, cudaMemcpyHostToDevice);

  // free(host_idata);
  memset(sum, 0, N*sizeof(int));
  // memset(sum, 0, sizeof(int));
  // sum = 0;
  cudaMemcpy(odata, sum, N*sizeof(int), cudaMemcpyHostToDevice);
  // cudaMemcpy(odata, &sum, sizeof(int), cudaMemcpyHostToDevice);

  // dim3 block(BLOCK, BLOCK);
  // dim3 grid(sz/100*BLOCK,1);
  
  iStart_cpu2 = cpuSecond();
  // countAlphaOnGPU<<<grid,block>>>(idata, odata);
  // countAlphaOnGPU<<<4048,1024>>>(idata, odata);
  countAlphaOnGPU<<<sz/(LINE_SIZE*BLOCK)+1,BLOCK>>>(idata, odata, LINE_SIZE);
  iElaps_cpu2 = cpuSecond() - iStart_cpu2;
  // reduction0<<<2,256>>>(idata, odata);

  cudaMemcpy(sum, odata, N*sizeof(int), cudaMemcpyDeviceToHost);
  // cudaMemcpy(&sum, odata, sizeof(int), cudaMemcpyDeviceToHost);

  int i = 0;
  for (char c = 'a'; c <= 'z'; c++, i++) {
    printf("%c, %d\n", c ,sum[i]);
  }

  cudaFree(idata);
  cudaFree(odata);
  free(sum);
  free(fp2);
  fclose(fp);

  iElaps_cpu = cpuSecond() - iStart_cpu;
  printf("Time elapsed %f sec\n", iElaps_cpu);
  printf("Time elapsed %f sec (計算部分のみ)\n", iElaps_cpu2);
  printf("Time elapsed %f sec (cudaMalloc)\n", iElaps_cpu3);
  printf("Time elapsed %f sec (1charずつ)\n", iElaps_cpu4);
  printf("Time elapsed %f sec (1行ずつ)\n", iElaps_cpu5);

  return 0;
}