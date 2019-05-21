#include "kernel/common.cl"

__kernel void vie_global (__global unsigned *in, __global unsigned *out)
{
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
  
  if (in[y*DIM+x] != 0) {

    if (neighboors != 3 && neighboors != 4) {
      color = 0;
    }
    else {
      color = 0xFFFF00FF;
    }
  }

  else {
    if (neighboors == 3) {
      color = 0xFFFF00FF;
    }
    else {
      color = 0;
    }
  }
 
  out[y*DIM+x] = color;

}

__kernel void vie (__global unsigned *in, __global unsigned *out)
{
  int x = get_global_id (0); 
  int y = get_global_id (1);

  __local unsigned tile[TILEY][TILEX];

  int x_loc = get_local_id(0);
  int y_loc = get_local_id(1);

  tile [x_loc][y_loc] = in[y*DIM+x];

  barrier(CLK_LOCAL_MEM_FENCE);
  unsigned neighboors = 0;
  unsigned color;
  
  if (x_loc > 0 && x_loc < TILEX - 1 && y_loc > 0 && y_loc < TILEY - 1) { // si on est pas sur les bords
    for (int i = y_loc - 1; i <= y_loc + 1; i++) {
      for (int j = x_loc - 1; j <= x_loc + 1; j++) {
  	if (tile[j][i] != 0)
  	  neighboors++;
      }
    }
  }

  else {
    if (x > 0 && x < DIM - 1 && y > 0 && y < DIM - 1) { // si on n'est pas sur les bords, il faut regarder dehors
      for (int i = y - 1; i <= y + 1; i++) {
  	for (int j = x - 1; j <= x + 1; j++) {
  	    if (in[i*DIM+j] != 0)
  	      neighboors++;
  	}
      }
    }
  }
  
  if (tile[x_loc][y_loc] != 0) { // vivant
    if (neighboors != 3 && neighboors != 4) { // mort si on n'a pas 2 ou 3 voisins
      color = 0;
    }
    else {
      color = 0xFFFF00FF;
    }
  }
  
  else { // mort
    if (neighboors == 3) { // vivant si on a 3 voisins
      color = 0xFFFF00FF;
    }
    else {
      color = 0;
    }
  }

  out[y*DIM+x] = color;

}
