#include "kernel/common.cl"

__kernel void vie_g (__global unsigned *in, __global unsigned *out)
{
  // aqui vem a posicao do pixel em si
  int x = get_global_id (0); 
  int y = get_global_id (1);

  unsigned neighboors = 0;
  unsigned color;
  
  if (x > 0 && x < DIM - 1 && y > 0 && y < DIM - 1) {
    for (int i = y - 1; i <= y + 1; i++) {
      for (int j = x - 1; j <= x + 1; j++) {
	if (in[i*DIM+j] != 0)
	  neighboors++;	
      }
    }
  }
  
  if (in[y*DIM+x] != 0) { // se eu tava vivo

    if (neighboors != 3 && neighboors != 4) { // eu morro se n tiver 2 ou 3 vizinhos
      color = 0;
    }
    else {
      color = 0xFFFF00FF;
    }
  }

  else { // se eu tava morto
    if (neighboors == 3) { // se tenho 3 vizinhos
      color = 0xFFFF00FF; // ressucitei
    }
    else {
      color = 0;
    }
  }
 
  out[y*DIM+x] = color;

}

__kernel void vie2 (__global unsigned *in, __global unsigned *out)
{
  int x = get_global_id (0); 
  int y = get_global_id (1);

  __local unsigned tile[TILEY+2][TILEX+2];

  int x_loc = get_local_id(0);
  int y_loc = get_local_id(1);

  tile [x_loc][y_loc] = in[y*DIM+x];

  if (x > 0 && x < DIM -1 && y > 0 && y < DIM -1) {
    tile[x_loc-1][y_loc-1] = in [(y-1)*DIM+x-1];
    tile[x_loc-1][y_loc+1] = in [(y+1)*DIM+x-1];
    tile[x_loc+1][y_loc-1] = in [(y-1)*DIM+x+1];
    tile[x_loc+1][y_loc+1] = in [(y+1)*DIM+x+1];
  }

  barrier(CLK_LOCAL_MEM_FENCE);
  unsigned neighboors = 0;
  unsigned color;
  
  if (x > 0 && x < DIM - 1 && y > 0 && y < DIM - 1) {
    for (int i = y_loc - 1; i <= y_loc + 1; i++) {
      for (int j = x_loc - 1; j <= x_loc + 1; j++) {
	if (tile[j][i] != 0)
	  neighboors++;
      }
    }
  }

  /* else { */
  /*   if (x > 0 && x < DIM - 1 && y > 0 && y < DIM - 1) { */
  /*     for (int i = y - 1; i <= y + 1; i++) { */
  /* 	for (int j = x - 1; j <= x + 1; j++) { */
  /* 	  if (i != y || j != x) { */
  /* 	    if (in[i*DIM+j] != 0) */
  /* 	      neighboors++; */
  /* 	  } */
  /* 	} */
  /*     } */
  /*   } */
  /* } */
  
  if (tile[x_loc][y_loc] != 0) { // se eu tava vivo
    if (neighboors != 3 && neighboors != 4) { // eu morro se n tiver 2 ou 3 vizinhos
      color = 0;
    }
    else {
      color = 0xFFFF00FF;
    }
  }
  
  else { // se eu tava morto
    if (neighboors == 3) { // se tenho 3 vizinhos
      color = 0xFFFF00FF; // ressucitei
    }
    else {
      color = 0;
    }
  }

  out[y*DIM+x] = color;

}

// vivo = 0xFFFF00FF
