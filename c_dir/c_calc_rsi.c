#include <string.h>
#include <stdio.h>
#include <math.h>


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
  float calc_rsi();
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
fprintf(stdout,"%f\n",calc_rsi (14,(num_lines-1),stock_data_ptr_start));
return 0;  
}

float calc_rsi (ndays, nsamples, stock_data_ptr) 
     int ndays;
     int nsamples;

     struct stock_data *stock_data_ptr;
{
int last_sample,sample;
struct stock_data *stock_data_ptr_m1;
float period_gain,period_loss,change;
float *rsi_ptr, *rsi_ptr_start;

rsi_ptr_start = (float *) malloc(nsamples * sizeof(float));
rsi_ptr = rsi_ptr_start;

last_sample = nsamples - 1;
stock_data_ptr = stock_data_ptr + nsamples - 1; //set ptr to oldest sample
rsi_ptr = rsi_ptr + nsamples - 1;

//fprintf(stdout,"%s %f %f %f %f %i %f\n",stock_data_ptr->date,stock_data_ptr->open,stock_data_ptr->high,stock_data_ptr->low,stock_data_ptr->close,stock_data_ptr->volume,stock_data_ptr->aclose);

period_gain=0;
period_loss=0;
for (sample=last_sample;sample > last_sample - ndays;sample--)
{
  stock_data_ptr_m1 = stock_data_ptr - 1;
  change=stock_data_ptr_m1->close - stock_data_ptr->close;

  if (change > 0) 
    period_gain=period_gain + change;
  else
    period_loss=period_loss + change;

  stock_data_ptr--;
  rsi_ptr--;
}
 period_gain = period_gain/(float)ndays;
 period_loss = period_loss/(float)ndays;
      
 if (period_loss != 0)
   *(rsi_ptr - 2) = 100.0 - (100.0/(1.0 + period_gain/fabs(period_loss)));
 else
   *(rsi_ptr - 2) = 0.0;
for (sample=sample;sample > 0;sample--)
{
  stock_data_ptr_m1 = stock_data_ptr - 1;
  change=stock_data_ptr_m1->close - stock_data_ptr->close;

  if (change > 0) 
    {
      period_gain = ((period_gain * (ndays - 1)) + change)/(float)ndays;
      period_loss = ((period_loss * (ndays - 1)) +    0  )/(float)ndays;
    }
  else
    {
      period_gain = ((period_gain * (ndays - 1)) +    0  )/(float)ndays;
      period_loss = ((period_loss * (ndays - 1)) + change)/(float)ndays;
    }
  if (period_loss != 0) 
    {
      *(rsi_ptr -1) = 100 - (100/(1 + period_gain/fabs(period_loss)));
    }
  else
    {
      *(rsi_ptr -1) = 0;
    }
  //  fprintf(stdout,"period_gain = %f, period_loss = %f, rsi = %f\n",period_gain,period_loss,*(rsi_ptr - 1) );

  stock_data_ptr--;
  rsi_ptr--;
}
rsi_ptr = (rsi_ptr_start + nsamples - 1);
#if 0
for (sample=last_sample;sample > -1;sample--)
{
  fprintf(stdout,"RSI(%d): %f\n",sample,*(rsi_ptr));
  rsi_ptr--;
}
#endif
return *rsi_ptr_start;
}    

