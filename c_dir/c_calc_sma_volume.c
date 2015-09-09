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
  float sma;
};

int main (argc, argv)
     int argc;
     char *argv[];
{
  float calc_sma_volume();
  int i,sample,num_lines;
  FILE *fin;
  char *my_buffer_ptr;
  char my_buffer[256],my_buffer2[256];
  char sdate[10];
  float sopen,shigh,slow,sclose,saclose;
  int svolume, num_smadays;
  float sma;
  
  
  struct stock_data *stock_data_ptr, *stock_data_ptr_start;
 
  if (0) {
    fprintf (stdout,"ARGC: %d\n",argc);
    fprintf (stdout,"ARGV0: %s\n",argv[0]);
    fprintf (stdout,"ARGV1: %s\n",argv[1]);
    fprintf (stdout,"ARGV2: %s\n",argv[2]);
  }
  sscanf(argv[1],"%d",&num_lines);
  sscanf(argv[3],"%d",&num_smadays);
  //fprintf (stdout,"%d\n",num_lines);
  stock_data_ptr_start = (struct stock_data *) malloc((num_lines-1) * sizeof(struct stock_data)); 
  stock_data_ptr = stock_data_ptr_start;
  sscanf(argv[2],"%s",my_buffer);
  //fprintf(stdout,"%s\n",my_buffer);
  fin = fopen(my_buffer,"r");
  //fin = fopen("../historical_data/scmr.dat","r");
  fgets(my_buffer,255,fin); // read off headr line
  // read contents of file into memory, most recent is at beginning (i.e. stock_data_ptr_start)
  // oldest at end (i.e. stock_data_ptr_start + (num_lines -1)
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

sma = calc_sma_volume (num_smadays,(num_lines-1),stock_data_ptr_start);

stock_data_ptr = stock_data_ptr_start + num_lines - 2;
for (sample = (num_lines - 2);sample > -1;sample--) 
{
  fprintf(stdout,"%i %f ",sample,stock_data_ptr->sma);
  stock_data_ptr --;
}
return 0;  
}

float calc_sma_volume (ndays, nsamples, stock_data_ptr) 
     int ndays;
     int nsamples;
     
     struct stock_data *stock_data_ptr;
{
int debug=0;
struct stock_data *local_ptr, *oldest_sample_ptr;

int last_sample,sample;
float period_total;

// move to oldest data
local_ptr = stock_data_ptr + nsamples - 1;
last_sample = nsamples - 1;

period_total = 0;
for (sample = last_sample; sample > last_sample - ndays; sample--)
{
  if (debug == 1) {
    fprintf(stdout,"sample = %i\n",sample);
    fprintf(stdout,"volume  = %f\n",local_ptr->volume);
  }
  period_total = period_total + local_ptr->volume;
  local_ptr--;
}    
 local_ptr++; // backup one sample as this is the sample to which first sma belongs
 local_ptr->sma = period_total/ndays;
 local_ptr--;
 for (sample=sample;sample>-1;sample--)
   {
     // remove oldest part of period total
     oldest_sample_ptr = local_ptr + ndays;
     period_total = period_total - oldest_sample_ptr->volume;
     // add newest part of period total
     period_total = period_total + local_ptr->volume;
     // recompute sma
     local_ptr->sma = period_total/ndays;
     if (0) 
       {
	 fprintf (stdout,"period_total=\t%f\n",period_total);
	 fprintf (stdout,"SMA=\t%f\n",local_ptr->sma);
       }
     local_ptr --;
   }
 local_ptr ++;
 if (0) 
   {
     fprintf (stdout,"sdps = %i\n",stock_data_ptr);
     fprintf (stdout,"lptr = %i\n",local_ptr);
   }
 return stock_data_ptr->sma;
}
 
 
