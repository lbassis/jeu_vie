#include "kernel/common.cl"

__kernel void vie_global (__global unsigned *in, __global unsigned *out, __global unsigned *a, __global unsigned *b, __global unsigned *g)
{
  int x = get_global_id (0); 
  int y = get_global_id (1);

  unsigned color, neighboors = 0;
  
  if (not_border(x, y)) {
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

__kernel void vie_semi_local (__global unsigned *in, __global unsigned *out, __global unsigned *a, __global unsigned *b, __global unsigned *g)
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
    if (not_border(x, y)) { // si on n'est pas sur les bords, il faut regarder dehors
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

__kernel void vie2 (__global unsigned *in, __global unsigned *out, __global unsigned *a, __global unsigned *b, __global unsigned *g)
{
  int x = get_global_id (0); 
  int y = get_global_id (1);

  __local unsigned tile[TILEY+2][TILEX+2];

  int x_loc = get_local_id(0);
  int y_loc = get_local_id(1);

  
  unsigned neighboors = 0;
  unsigned color;

  tile [x_loc+1][y_loc+1] = in[y*DIM+x];
  if (not_border(x, y)) { //si on n'est pas sur la borde, on peut prendre tous les voisines
    tile[x_loc][y_loc] = in[(y-1)*DIM+(x-1)];
    tile[x_loc][y_loc+1] = in[y*DIM+(x-1)];
    tile[x_loc][y_loc+2] = in[(y+1)*DIM+(x-1)];

    tile[x_loc+2][y_loc] = in[(y-1)*DIM+(x+1)];
    tile[x_loc+2][y_loc+1] = in[y*DIM+(x+1)];
    tile[x_loc+2][y_loc+2] = in[(y+1)*DIM+(x+1)];

    tile[x_loc+1][y_loc+2] = in[(y+1)*DIM+x];
    tile[x_loc+1][y_loc] = in[(y-1)*DIM+x];
  }  

  barrier(CLK_LOCAL_MEM_FENCE);

  if (not_border(x, y)) {
    for (int i = y_loc; i <= y_loc + 2; i++) {
      for (int j = x_loc; j <= x_loc + 2; j++) {
	if (tile[j][i] != 0)
	  neighboors++;
      }
    }
    
    if (tile[x_loc+1][y_loc+1] != 0) { // vivant
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
  else
    out[y*DIM+x] = 0;
}


static void print_changed(__global unsigned *in, __global unsigned *out, unsigned grain) {

  /* printf("in:\n"); */
  /* for (int i = 0; i < grain+2; i++) { */
  /*   for (int j = 0; j < grain+2; j++) { */
  /*     if (in[j*(grain+2)+i] == 1) */
  /* 	printf("*"); */
  /*     else */
  /* 	printf("-"); */
  /*   } */
  /*   printf("\n"); */
  /* } */

  printf("out:\n");
  for (int i = 1; i < grain+1; i++) {
    for (int j = 1; j < grain+1; j++) {
      if (out[i*(grain+2)+j] == 1)
	printf("*");
      else
	printf("-");
    }
    printf("\n");
  }
  
  
}

__kernel void vie (__global unsigned *in, __global unsigned *out, __global unsigned *changed_in, __global unsigned *changed_out, __global unsigned *grain)
{

  unsigned g = *grain;
  int x = get_global_id (0); 
  int y = get_global_id (1);
  int x_loc = x*g/DIM; 
  int y_loc = y*g/DIM; 

  unsigned color, neighboors = 0;

  if (neighborhood_changed(g, x_loc, y_loc, changed_in) && not_border(x, y)) {
    for (int i = y - 1; i <= y + 1; i++) {
      for (int j = x - 1; j <= x + 1; j++) {
	if (in[i*DIM+j] != 0)
	  neighboors++;	
      }
    }
  
    if (in[y*DIM+x] != 0) {
      if (neighboors != 3 && neighboors != 4) {
	color = 0;
	tile_changed(g, x_loc, y_loc, 1, changed_out);
      }
      else {
	color = 0xFFFF00FF;
      }
    }
    else {
      if (neighboors == 3) {
	color = 0xFFFF00FF;
	tile_changed(g, x_loc, y_loc, 1, changed_out);
      }
      else {
	color = 0;
      }
    }
    out[y*DIM+x] = color;
  }
  
  else {
    out[y*DIM+x] = in[y*DIM+x];
  }

  /* barrier(CLK_LOCAL_MEM_FENCE);
  if (x == 0 && y == 0)
  print_changed(changed_in, changed_out, *grain); */
}


