#include <string.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define DEBUG 0

struct stock_data {
  char date[10];
  float open;
  float high;
  float low;
  float close;
  int volume;
  float aclose;
  float volatility;
};

int main (argc, argv)
     int argc;
     char *argv[];
{
  float calc_volatility();
  int i,sample,num_lines;
  FILE *fin;
  char *my_buffer_ptr;
  char my_buffer[256],my_buffer2[256];
  char sdate[10];
  float sopen,shigh,slow,sclose,saclose;
  int svolume, num_volatilitydays;
  float volatility;
  
  
  struct stock_data *stock_data_ptr, *stock_data_ptr_start;
 
  if (DEBUG) {
    fprintf (stdout,"ARGC: %d\n",argc);
    fprintf (stdout,"ARGV0: %s\n",argv[0]);
    fprintf (stdout,"ARGV1: %s\n",argv[1]);
    fprintf (stdout,"ARGV2: %s\n",argv[2]);
    fprintf (stdout,"ARGV3: %s\n",argv[3]);
  }
  sscanf(argv[1],"%d",&num_lines);
  sscanf(argv[3],"%d",&num_volatilitydays);
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
      if (feof(fin)) {;break;}
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
      sscanf(my_buffer,							\
	     "%s%f%f%f%f%i%f",&stock_data_ptr->date,&stock_data_ptr->open,&stock_data_ptr->high,&stock_data_ptr->low,&stock_data_ptr->close,&stock_data_ptr->volume,&stock_data_ptr->aclose);
      //            sscanf(my_buffer,"%s%f%f%f%f%i%f",stock.date,&stock.open,&stock.high,&stock.low,&stock.close,&stock.volume,&stock.aclose);
      //fprintf(stdout,"%s %f %f %f %f %i %f\n",stock_data_ptr->date,stock_data_ptr->open,stock_data_ptr->high,stock_data_ptr->low,stock_data_ptr->close,stock_data_ptr->volume,stock_data_ptr->aclose);
      stock_data_ptr++;
    }
  stock_data_ptr--;
  for (i=0;i < (num_lines - 1);i++)
    {
      //fprintf(stdout,"%s %f %f %f %f %i %f\n",stock_data_ptr->date,stock_data_ptr->open,stock_data_ptr->high,stock_data_ptr->low,stock_data_ptr->close,stock_data_ptr->volume,stock_data_ptr->aclose);
      stock_data_ptr--;
    }
  
  volatility = calc_volatility (num_volatilitydays,(num_lines-1),stock_data_ptr_start);
  
  stock_data_ptr = stock_data_ptr_start + num_lines - 2;
  for (sample = (num_lines - 2);sample > -1;sample--) 
    {
      fprintf(stdout,"%i %f ",sample,stock_data_ptr->volatility);
      stock_data_ptr --;
    }
  return 0;  
}

float calc_volatility (ndays, nsamples, stock_data_ptr) 
     int ndays;
     int nsamples;
     
     struct stock_data *stock_data_ptr;
{
  int debug=0;
struct stock_data *local_ptr, *oldest_sample_ptr;

 int last_sample,sample,std_dev_sample;
 float period_total_mean_price, period_total_std_dev;
 float stat_mean;
 int first_average;

// move to oldest data
local_ptr = stock_data_ptr + nsamples - 1;
last_sample = nsamples - 1;

period_total_mean_price = 0;
//compute initial statistcial mean over ndays starting with oldest data
for (sample = last_sample; sample > last_sample - ndays; sample--)
{
  if (debug == 1) {
    fprintf(stdout,"sample = %i\n",sample);
    fprintf(stdout,"close  = %f\n",local_ptr->aclose);
    fflush(stdout);
  }
  period_total_mean_price = period_total_mean_price + local_ptr->aclose;
  local_ptr--;
}    

 sample++;
 first_average=1;
 for (sample=sample;sample>-1;sample--)
   {
     if (first_average)
       {
	 first_average=0;
	 local_ptr += ndays;
       }
     else
       {
	 // remove oldest part of period total
	 oldest_sample_ptr = local_ptr + ndays;
	 period_total_mean_price = period_total_mean_price - oldest_sample_ptr->aclose;
	 //fprintf(stdout,"Removing %f\n",oldest_sample_ptr->aclose);
	 // add newest part of period total
	 period_total_mean_price = period_total_mean_price + local_ptr->aclose;
	 //fprintf(stdout,"Adding %f\n",local_ptr->aclose);
	 local_ptr += ndays-1;
       }

     //local_ptr--;
     stat_mean = period_total_mean_price/ndays;
     period_total_std_dev=0;
     for (std_dev_sample=0; std_dev_sample < ndays; std_dev_sample++)
       {
	 
	 period_total_std_dev = pow((stat_mean - local_ptr->aclose),2) + period_total_std_dev;
	 //fprintf(stdout,"data = %f\n",local_ptr->aclose);
	 local_ptr--;
       }    
     local_ptr->volatility = sqrt(period_total_std_dev/ndays);
     if (debug)
       {
	 fprintf(stdout,"Sample = %d\n",sample);
	 fprintf(stdout,"period_total_mean_price = %f\n",period_total_mean_price);
	 fprintf(stdout,"Stat_mean = %f\n",stat_mean);
	 fprintf(stdout,"Stat_m = %f\n",stat_mean);
	 fprintf(stdout,"Sum of std_dev = %f\n",period_total_std_dev);
	 fprintf(stdout,"Volatility = %f\n",local_ptr->volatility);
	 //	 fprintf(stdout,"local_ptr = %ll\n",local_ptr);
	 fflush(stdout);
       }
     
   }
 return stock_data_ptr->volatility;

 
 


#if 0
 local_ptr++; // backup one sample as this is the sample to which first volatility belongs
 local_ptr->volatility = period_total/ndays;
 local_ptr--;



 //future moving average statistical means require removing oldest data point and adding 1 new data point 
 for (sample=sample;sample>-1;sample--)
   {
     // remove oldest part of period total
     oldest_sample_ptr = local_ptr + ndays;
     period_total = period_total - oldest_sample_ptr->aclose;
     // add newest part of period total
     period_total = period_total + local_ptr->aclose;
     // recompute volatility
     local_ptr->volatility = period_total/ndays;
     if (0) 
       {
	 fprintf (stdout,"period_total=\t%f\n",period_total);
	 fprintf (stdout,"VOLATILITY=\t%f\n",local_ptr->volatility);
       }
     local_ptr --;
   }
 local_ptr ++;
 if (0) 
   {
     fprintf (stdout,"sdps = %i\n",stock_data_ptr);
     fprintf (stdout,"lptr = %i\n",local_ptr);
   }
#endif
}
 
 
