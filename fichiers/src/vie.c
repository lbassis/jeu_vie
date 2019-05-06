
#include "compute.h"
#include "debug.h"
#include "global.h"
#include "graphics.h"
#include "ocl.h"
#include "scheduler.h"

#include <stdbool.h>

extern unsigned *cur_modified;
extern unsigned *last_modified;

static int compute_new_state (int y, int x)
{
  unsigned n      = 0;
  unsigned change = 0;

  if (x > 0 && x < DIM - 1 && y > 0 && y < DIM - 1) {
    for (int i = y - 1; i <= y + 1; i++)
      for (int j = x - 1; j <= x + 1; j++)
        if (i != y || j != x)
          n += (cur_img (i, j) != 0);

    if (cur_img (y, x) != 0) {
      if (n == 2 || n == 3)
        n = 0xFFFF00FF;
      else {
        n      = 0;
        change = 1;
      }
    } else {
      if (n == 3) {
        n      = 0xFFFF00FF;
        change = 1;
      } else
        n = 0;
    }

    next_img (y, x) = n;
  }

  return change;
}

static int traiter_tuile (int i_d, int j_d, int i_f, int j_f)
{
  unsigned change = 0;

  PRINT_DEBUG ('c', "tuile [%d-%d][%d-%d] traitée\n", i_d, i_f, j_d, j_f);

  for (int i = i_d; i <= i_f; i++)
    for (int j = j_d; j <= j_f; j++)
      change |= compute_new_state (i, j);

  return change;
}

// Renvoie le nombre d'itérations effectuées avant stabilisation, ou 0
unsigned vie_compute_seq (unsigned nb_iter)
{
  for (unsigned it = 1; it <= nb_iter; it++) {

    // On traite toute l'image en un coup (oui, c'est une grosse tuile)
    unsigned change = traiter_tuile (0, 0, DIM - 1, DIM - 1);

    swap_images ();

    if (!change)
      return it;
  }

  return 0;
}

unsigned vie_compute_tuile (unsigned nb_iter)
{

  int tile_size = DIM/GRAIN;
  unsigned change = 0;

  for (unsigned it = 1; it <= nb_iter; it++) {
    for (int i = 0; i < GRAIN; i++) {
      for (int j = 0; j < GRAIN; j++) {
	change += traiter_tuile (i*tile_size, j*tile_size, (i+1)*tile_size-1, (j+1)*tile_size-1);
      }
    }
    swap_images ();
    
    if (!change)
      return it;
  }

  return 0;
}


void print_modified(int a) {
  if (a == 0)
    for (unsigned i = 0; i < GRAIN+2; i++) {
      for (unsigned j = 0; j < GRAIN+2; j++) {
	printf("%u ", last_modified[j+GRAIN*i]);
      }
      printf("\n");
    }
  else {
   for (unsigned i = 0; i < GRAIN+2; i++) {
      for (unsigned j = 0; j < GRAIN+2; j++) {
	printf("%u ", cur_modified[j+GRAIN*i]);
      }
      printf("\n");
    }
  }
}
unsigned has_tile_changed(unsigned i, unsigned j) {
  i++;
  j++;
  return last_modified[j+GRAIN*i];
}

void tile_changed(unsigned i, unsigned j, unsigned value) {
  i++;
  j++;
  cur_modified[j+GRAIN*i] = value;
}

unsigned neighborhood_changed(unsigned x, unsigned y) {

  unsigned n = 0;
    
  for (unsigned i = y-1; i <= y+1; i++) {
    for (unsigned j = x-1; j <= x+1; j++) {
      n += has_tile_changed(i, j);
    }
  }
  //  return 1;
  //printf("n = %u at %u %u\n", n, x, y);
  return n;
}

unsigned vie_compute_tuile_opt (unsigned nb_iter)
{

  int tile_size = DIM/GRAIN;
  unsigned change = 0;
  unsigned value = 0;
  
  for (unsigned it = 1; it <= nb_iter; it++) {
    for (unsigned i = 0; i < GRAIN; i++) {
      for (unsigned j = 0; j < GRAIN; j++) {
	if (neighborhood_changed(i, j) != 0) { // if the tile or its neighboors has changed
	  value = traiter_tuile (i*tile_size, j*tile_size, (i+1)*tile_size-1, (j+1)*tile_size-1);
	  change += value; // to see if it's already over or not
	  tile_changed(i, j, value);
	  }
      }
    }
    
    swap_images ();
    print_modified(0);
    printf("___________________________\n");
    print_modified(1);
    
    for (unsigned i = 0; i < GRAIN+2; i++) {
      for (unsigned j = 0; j < GRAIN+2; j++) {
	last_modified[j+i*GRAIN] = cur_modified[j+i*GRAIN];
      }
    }
    //memcpy(last_modified, cur_modified, (GRAIN+2)*(GRAIN+2)*sizeof(unsigned));
    
    if (!change)
      return it;
  }

  return 0;
}


void vie_init() {

  // mallocs
  cur_modified = malloc((GRAIN+2)*(GRAIN+2)*sizeof(unsigned));
  last_modified = malloc((GRAIN+2)*(GRAIN+2)*sizeof(unsigned));

  for (unsigned i = 0; i < (GRAIN+2)*(GRAIN+2); i++) {
    last_modified[i] = 1;
    cur_modified[i] = 1; // in order to make the borders still 1 after the first memcpy
  }
  
  //printf("init!\n");
}

void vie_finalize() {

  free(cur_modified);
  free(last_modified);
  // frees
}

//void vie_refresh_img() {

  // on peut creer notre propre tableau de bool pour faire le jeu et donc ici on fait cur_img(i,j) = tab[i][j] juste pour montrer que ca marche

//}
///////////////////////////// Configuration initiale

void draw_stable (void);
void draw_guns (void);
void draw_random (void);
void draw_clown (void);
void draw_diehard (void);

void vie_draw (char *param)
{
  char func_name[1024];
  void (*f) (void) = NULL;

  if (param == NULL)
    f = draw_guns;
  else {
    sprintf (func_name, "draw_%s", param);
    f = dlsym (DLSYM_FLAG, func_name);

    if (f == NULL) {
      PRINT_DEBUG ('g', "Cannot resolve draw function: %s\n", func_name);
      f = draw_guns;
    }
  }

  f ();
}

static unsigned couleur = 0xFFFF00FF; // Yellow

static void gun (int x, int y, int version)
{
  bool glider_gun[11][38] = {
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0,
       0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0,
       0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0},
      {0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0,
       0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1,
       0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0,
       0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
      {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
  };

  if (version == 0)
    for (int i = 0; i < 11; i++)
      for (int j = 0; j < 38; j++)
        if (glider_gun[i][j])
          cur_img (i + x, j + y) = couleur;

  if (version == 1)
    for (int i = 0; i < 11; i++)
      for (int j = 0; j < 38; j++)
        if (glider_gun[i][j])
          cur_img (x - i, j + y) = couleur;

  if (version == 2)
    for (int i = 0; i < 11; i++)
      for (int j = 0; j < 38; j++)
        if (glider_gun[i][j])
          cur_img (x - i, y - j) = couleur;

  if (version == 3)
    for (int i = 0; i < 11; i++)
      for (int j = 0; j < 38; j++)
        if (glider_gun[i][j])
          cur_img (i + x, y - j) = couleur;
}

void draw_stable (void)
{
  for (int i = 1; i < DIM - 2; i += 4)
    for (int j = 1; j < DIM - 2; j += 4)
      cur_img (i, j) = cur_img (i, (j + 1)) = cur_img ((i + 1), j) =
          cur_img ((i + 1), (j + 1))        = couleur;
}

void draw_guns (void)
{
  memset (&cur_img (0, 0), 0, DIM * DIM * sizeof (cur_img (0, 0)));

  gun (0, 0, 0);
  gun (0, DIM - 1, 3);
  gun (DIM - 1, DIM - 1, 2);
  gun (DIM - 1, 0, 1);
}

void draw_random (void)
{
  for (int i = 1; i < DIM - 1; i++)
    for (int j = 1; j < DIM - 1; j++)
      cur_img (i, j) = random () & 01;
}

void draw_clown (void)
{
  memset (&cur_img (0, 0), 0, DIM * DIM * sizeof (cur_img (0, 0)));

  int mid                = DIM / 2;
  cur_img (mid, mid - 1) = cur_img (mid, mid) = cur_img (mid, mid + 1) =
      couleur;
  cur_img (mid + 1, mid - 1) = cur_img (mid + 1, mid + 1) = couleur;
  cur_img (mid + 2, mid - 1) = cur_img (mid + 2, mid + 1) = couleur;
}

void draw_diehard (void)
{
  memset (&cur_img (0, 0), 0, DIM * DIM * sizeof (cur_img (0, 0)));

  int mid = DIM / 2;

  cur_img (mid, mid - 3) = cur_img (mid, mid - 2) = couleur;
  cur_img (mid + 1, mid - 2)                      = couleur;

  cur_img (mid - 1, mid + 3)     = couleur;
  cur_img (mid + 1, mid + 2)     = cur_img (mid + 1, mid + 3) =
      cur_img (mid + 1, mid + 4) = couleur;
}
