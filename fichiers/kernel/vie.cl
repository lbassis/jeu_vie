#include "kernel/common.cl"

__kernel void transpose (__global unsigned *in, __global unsigned *out)
{
  int x = get_global_id (0);
  int y = get_global_id (1);

  __local unsigned tile[TILEY][TILEX];

  int x_loc = get_local_id(0);
  int y_loc = get_local_id(1);
  
  tile [x_loc][y_loc] = in [y * DIM + x];

  int offset_x = y-y_loc+x_loc;
  int offset_y = x-x_loc+y_loc;
  barrier(CLK_LOCAL_MEM_FENCE);
  out[DIM*offset_y+offset_x] = tile[y_loc][x_loc];
}


static int compute_new_state (int y, int x, __local unsigned **tile)
{

  //    return n;
    //next_img (y, x) = n;
  //}

  //return change;
}


__kernel void vie (__global unsigned *in, __global unsigned *out)
{

  /* // one tile per core */
  /* // one grain per group */
  
  /* int x = get_local_id (0); // [0, TILEX] position inside in */
  /* int y = get_local_id (1); // [0, TILEY] */

  /* __local unsigned tile[TILEY][TILEX]; */

  /* int global_x = TILEX * get_global_id(0) + x; // position inside the grain */
  /* int global_y = TILEY * get_global_id(1) + y; */

  /* tile [x][y] = in [global_y * DIM + global_x]; */
  /* barrier(CLK_LOCAL_MEM_FENCE); */

  /* //for (unsigned i = global_y; i < TILEY; i++) { */
  /* // for (unsigned j = global_x; j < TILEX; j++) { */
  /* out[global_x * DIM + global_y] = 0xFFFF00FF; */
  /*     //} */
  /*     //} */



  
  // aqui vem a posicao do pixel em si
  int x = get_global_id (0); 
  int y = get_global_id (1);

  __local unsigned tile[TILEY][TILEX];

  // aqui vem a posicao do pixel dentro do grupo dele
  int x_loc = get_local_id(0);
  int y_loc = get_local_id(1);

  // copia pra memoria local o pixel
  tile [x_loc][y_loc] = in [y * DIM + x];


  unsigned neighboors = 0;
  unsigned color;
  
  if (x > 0 && x < DIM - 1 && y > 0 && y < DIM - 1) {
    for (int i = y - 1; i <= y + 1; i++) {
      for (int j = x - 1; j <= x + 1; j++) {
        if (i != y || j != x) {
	  if (in[i*DIM+j] != 0)
	    neighboors++;
	}
      }
    }
  }
  // aqui eu tenho em n a quantidade de vizinhos -> ta certo!!!!!!!
  
  if (in[y*DIM+x] != 0) { // se eu tava vivo

    if (neighboors != 2 && neighboors != 3) { // eu morro se n tiver 2 ou 3 vizinhos
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
    //color = 0;
  }
  
  //int offset_x = y-y_loc+x_loc;
  //int offset_y = x-x_loc+y_loc;
  barrier(CLK_LOCAL_MEM_FENCE);
  out[y*DIM+x] = color;

}

// vivo = 0xFFFF00FF
