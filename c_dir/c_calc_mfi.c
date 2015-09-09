#include <string.h>
#include <stdio.h>

struct stock_data {
    char date[10];
    float open;
    float high;
    float low;
    float close;
    int volume;
    float aclose;
  };

int main (argc, argv)
     int argc;
     char *argv[];
{
  float calc_mfi();
  int i,num_lines;
  FILE *fin;
  char *my_buffer_ptr;
  char my_buffer[256],my_buffer2[256];
  char sdate[10];
  float sopen,shigh,slow,sclose,saclose;
  int svolume;
  
  
  struct stock_data *stock_data_ptr, *stock_data_ptr_start;
  
  //fprintf (stdout,"ARGC: %d\n",argc);
  //fprintf (stdout,"ARGV0: %s\n",argv[0]);
  //fprintf (stdout,"ARGV1: %s\n",argv[1]);
  sscanf(argv[1],"%d",&num_lines);
  //fprintf (stdout,"%d\n",num_lines);
  stock_data_ptr_start = (struct stock_data *) malloc((num_lines-1) * sizeof(struct stock_data)); 
  stock_data_ptr = stock_data_ptr_start;
  sscanf(argv[2],"%s",my_buffer);
  //fprintf(stdout,"%s\n",my_buffer);
  fin = fopen(my_buffer,"r");
  //fin = fopen("../historical_data/scmr.dat","r");
  fgets(my_buffer,255,fin); // read off headr line
  while (!feof(fin))
    {
      fgets(my_buffer,255,fin);
      if (feof(fin)) {break;}
      for (i=0;i<strlen(my_buffer);i++)
	{
	  //	  fprintf(stdout,"%c",my_buffer[i]);
	  if (my_buffer[i] != 0) 
	    {
	      if (my_buffer[i] == ',')
		{
		  //		  fprintf(stdout,"Found a comma\n");
		  my_buffer[i] = ' ';
		}
	    }
	  else 
	    {
	      i = 256;
	    }
	}
      //fprintf(stdout,"%s\n",my_buffer);
      sscanf(my_buffer, \
	     "%s%f%f%f%f%i%f",&stock_data_ptr->date,&stock_data_ptr->open,&stock_data_ptr->high,&stock_data_ptr->low,&stock_data_ptr->close,&stock_data_ptr->volume,&stock_data_ptr->aclose);
      //            sscanf(my_buffer, \
	"%s%f%f%f%f%i%f",stock.date,&stock.open,&stock.high,&stock.low,&stock.close,&stock.volume,&stock.aclose);
  //fprintf(stdout,"%s %f %f %f %f %i %f\n",stock_data_ptr->date,stock_data_ptr->open,stock_data_ptr->high,stock_data_ptr->low,stock_data_ptr->close,stock_data_ptr->volume,stock_data_ptr->aclose);
  stock_data_ptr++;
}
stock_data_ptr--;
for (i=0;i < (num_lines - 1);i++)
{
  //  fprintf(stdout,"%s %f %f %f %f %i %f\n",stock_data_ptr->date,stock_data_ptr->open,stock_data_ptr->high,stock_data_ptr->low,stock_data_ptr->close,stock_data_ptr->volume,stock_data_ptr->aclose);
  stock_data_ptr--;
}
fprintf(stdout,"%f\n",calc_mfi(14,(num_lines-1),stock_data_ptr_start));
return 0;  
}

float calc_mfi (ndays, nsamples, stock_data_ptr) 
     int ndays;
     int nsamples;
     
     struct stock_data *stock_data_ptr;
{
struct stock_data *prev_day_ptr,*cur_day_ptr;
float mf_pos = 0.0, mf_neg = 0.0, cur_price,prev_price,mfi;
int first_day = ndays + 1, prev_day, cur_day;

for (prev_day=first_day;prev_day > 0; prev_day--)
{
  cur_day = prev_day - 1;
  cur_day_ptr = stock_data_ptr +  cur_day;
  //printf("current_day = %s\n",cur_day_ptr->date);
  prev_day_ptr = stock_data_ptr +  prev_day;
  //printf("prev_day = %s\n",prev_day_ptr->date);

  cur_price = (cur_day_ptr->high + cur_day_ptr->low + cur_day_ptr->close)/3.0;
  prev_price = (prev_day_ptr->high + prev_day_ptr->low + prev_day_ptr->close)/3.0;
  
 if (cur_price > (prev_price * 1.00001))
   mf_pos = mf_pos + (cur_price * cur_day_ptr->volume);
 else
   mf_neg = mf_neg + (cur_price * cur_day_ptr->volume);

 // printf("cur_price %f\n",cur_price);
 //printf("prev_price %f\n",prev_price);
 //printf("cur_vol = %d\n",cur_day_ptr->volume);
 //printf("MF_POS: %f\n",mf_pos);
 //printf("MF_NEG: %f\n",mf_neg);
}
 
  if (mf_neg == 0)
    mfi = 0.0;
  else
    mfi = 100.0 - (100.0/(1 + mf_pos/mf_neg));

return mfi;
}    

