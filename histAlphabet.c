#include <stdio.h>
#include <ctype.h> // isalnum()
#include <string.h> // stricmp()
#include <stdlib.h> // exit()
#include <sys/time.h>
#define N 26

struct wordTag{
    char alphabet;
    int count; // 出現回数
    float freq; // 出現頻度
};

struct wordTag a[N] = {};

void initWordTag() {
  char c;
  int i = 0;
  for (c = 'a' ; c <= 'z'; c++ ) {
    a[i].alphabet = c;
    a[i].count = 0;
    a[i].freq = 0;
    i++;
  }  
  return;
}

void struct_swap(int i, int j) {
  char tmp;
  int tmp2;
  float tmp3;

  tmp = a[i].alphabet;
  a[i].alphabet = a[j].alphabet;
  a[j].alphabet = tmp;
  tmp2 = a[i].count;
  a[i].count = a[j].count;
  a[j].count = tmp2;
  // tmp3 = a[i].freq;
  // a[i].freq = a[j].freq;
  // a[j].freq = tmp3;

  return;
}

void quick_sort(int left, int right) { // 降順
  int i, j, pivot;
  i = left; j = right;
  pivot = a[(i+j)/2].count;
  while(1) {
    while (a[i].count > pivot) i++; 
    while (a[j].count < pivot) j--;
    if (i >= j) break;
    struct_swap(i, j);
    i++; j--;
  }
  if (left < i-1) quick_sort(left, i-1);
  if (j+1 < right) quick_sort(j+1, right);
}

double cpuSecond() {
  struct timeval tp;
  gettimeofday(&tp, NULL);
  return ((double)tp.tv_sec + (double)tp.tv_usec*1.e-6);
}

int main(void){
  FILE *fp;
  char s[1024], *p;
  long sz;

  double iStart_cpu, iElaps_cpu;
  double iStart_cpu2, iElaps_cpu2;
  iStart_cpu = cpuSecond();

	if ( (fp=fopen("book4.txt","r"))==NULL ) {
		printf("File not open...\n");
		exit(1);
	}

  fseek(fp, 0, SEEK_END);
  sz = ftell(fp);
  printf("ファイルのサイズ : %ldバイト\n", sz);
  fseek(fp, 0, SEEK_SET);

  initWordTag();

  iStart_cpu2 = cpuSecond();
  /* ファイルの最後まで読み込んで単語数を格納 */
  while (fgets(s, 1024, fp) != NULL) {
    p = s; // p = &s[0]
    while (*p != '\0' && *p != '\n') { 
      while (isalpha(*p) != 0) { // if alphabet
        for (int i = 0; i < N; i++) {
          if (tolower(*p) == a[i].alphabet) {
            a[i].count++;
            break;
          }
        }
        p++;
      }
      p++;
    }
  }
  iElaps_cpu2 = cpuSecond() - iStart_cpu2;

  fclose(fp);
  // quick_sort(0, N-1);

  for (int i = 0; i < N; i++) { // CSVに出力
    printf("%c, %d\n", a[i].alphabet, a[i].count);
  }
  iElaps_cpu = cpuSecond() - iStart_cpu;
  printf("Time elapsed %f sec\n", iElaps_cpu);
  printf("Time elapsed %f sec (計算部分のみ)\n", iElaps_cpu2);

  return 0;
}