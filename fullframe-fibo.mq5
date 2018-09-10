//+------------------------------------------------------------------+
//|                                               fullframe-fibo.mq5 |
//|                                                     Jose Azevedo |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jose Azevedo"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Declare input variables
input int risklevel; // Level of risk
sinput uint numdims = 3; // Number of fibo band dimensions. Must be <= 3.
input bool conviction_mode; // Open additional positions in each fibo band
input string line_color; // Colors of the fib band transition lines
input string text_color; // Colors of the text on the lines

// Declare _fibLine struct
struct _fibLine
{
   double price;
   float factor;
   string label;
};

// Declare static variables
static float fiblevels[] = {0.0,0.236,0.382,0.5,0.618,0.784}; // fibonacci band levels
int fibarray = ArraySize(fiblevels); // = 6
_fibLine lines[7][6][6]; // Init Array with 3 dimension
double head; // top level of the fibo band
double tail; // bottom level of the fibo band
double ath; // all time high
double atl; // all time low
int pressure; // price pressure within fibo band
double ppp; // price per pip
double fullnum; // numbers before comma
double halfnum; // first number after comma
bool prz; // potential reversal zone
double ask; // current asking price
double bid; // current bid price
double ltt; // long term trend
double mtt; // medium term trend
double stt; // short term trend
long curr_chart = ChartID(); //

int OnInit()
{
   // Copy monthly rates into weekly array
   int barcount = Bars(NULL,PERIOD_W1); // number of bars on W1
   MqlRates weekly[]; // declare the struct
   ArraySetAsSeries(weekly, true); // set array to dynamic
   int copied = CopyRates(NULL,PERIOD_W1,0,barcount,weekly);
      if(copied<=0)
         Print("Error copying price data",GetLastError());
      else
         Print("Copied ",ArraySize(weekly)," bars into Weekly Bars Array");
   
   // Find the highest (ath) and lowest (atl) close
   double closes[];
   ArrayResize(closes,ArraySize(weekly));
      for(int i=0;i<ArraySize(weekly);i++)
         closes[i] = weekly[i].close; // fetch all close prices
   if(ArraySize(closes) <= 0)
   {
      error();
   } else {
      ath = closes[ArrayMaximum(closes,0,WHOLE_ARRAY)];
      atl = closes[ArrayMinimum(closes,0,WHOLE_ARRAY)];
      Print("The highest close for this chart is: ",ath);
      Print("The lowest close for this chart is: ",atl);
   }
   
   // Build the lines Array
   ArrayFree(lines);
   for(int dim=1;dim<=numdims;dim++) // Loop through num of dimensions
   {
      // For each dimension
      if(dim==1) // THE FIRST DIMENSION
      {
         double total=ath-atl; // Difference atl ath for fib calculation
            for(int j=0;j<fibarray;j++)
            {
               float percent = fiblevels[j]*100;
               lines[j][0][0].price = atl + (total*fiblevels[j]);
               lines[j][0][0].factor = fiblevels[j];
            }
            // --> Don't forget 100% in the first dimension
               lines[fibarray][0][0].price = ath;
               lines[fibarray][0][0].factor = 1;
               lines[fibarray][0][0].label = "D3:100% D2:100% D1:100%"; // Add D1 label here
      }
    
      else if(dim==2) // DIMENSION 2
      {
         for(int k=0;k<fibarray;k++) // loop through dim 1
         {
            double low = lines[k][0][0].price;
            double high = lines[k+1][0][0].price;
            double total = high - low;
               for(int m=0;m<fibarray;m++) // loop through dim 2
               {
                  float dimonepercent = fiblevels[k]*100; // percent of dim up
                  float percent = fiblevels[m]*100;
                  lines[k][m][0].price = low + (total*fiblevels[m]);
                  lines[k][m][0].factor = fiblevels[m];
               }
         }
      }
      else if(dim==3)
      {
         for(int n=0;n<fibarray;n++) // loop through dim 1
         {
            for(int p=0;p<fibarray;p++)
            {
            
               double low = lines[n][p][0].price;
               double high;
                  if(p==fibarray-1) // jump back to dim 1 (bigger than dim 2 and 3)
                  {
                     high = lines[n+1][0][0].price;
                  } else {
                     high = lines[n][p+1][0].price;
                  }
               double total = high - low;
                  for(int q=0;q<fibarray;q++) // loop through dim 3
                  {
                     float one_percent = fiblevels[n]*100; // label percentage
                     float two_percent = fiblevels[p]*100; // label percentage
                     float three_percent = fiblevels[q]*100; // label percentage
                        lines[n][p][q].price = low + (total*fiblevels[q]);
                        lines[n][p][q].factor = fiblevels[p];
                        lines[n][p][q].label = NULL; // Reset to avoid appending on redraw
                     StringAdd(lines[n][p][q].label,"D3:" + three_percent + "% "); // label
                     StringAdd(lines[n][p][q].label,"D2:" + two_percent + "% "); // label
                     StringAdd(lines[n][p][q].label,"D1:" + one_percent + "%"); // label
                  }
            }
         }
      }
      else // HYPERSPACE --> Error Message and Exit
      {
         string caption = "Error";
         string message = "You've selected more than 3 fib dimensions. Please reduce to 3 or less.";
            MessageBox(message,caption,MB_OK);
         return(INIT_FAILED);
      }    
   }    
  
   // Print all price lines to the chart
   Print("Cleaning the Chart");
   CleanChart();
   for(int l=0;l<=fibarray;l++) // Dim 1 Loop
   {      
      if(l==fibarray) 
      { 
          string label = lines[l][0][0].label;
          string price = lines[l][0][0].price;
          string priceline = DoubleToString(price,5);
          string time = TimeCurrent()+ 5*PeriodSeconds();
            ObjectCreate(curr_chart,priceline, OBJ_HLINE, 0, 0, price);
            ObjectCreate(curr_chart,label, OBJ_TEXT, 0, time, price);
            ObjectSetString(curr_chart,label,OBJPROP_TEXT,label);
            ObjectSetInteger(curr_chart,label,OBJPROP_FONTSIZE,8);
            ObjectSetInteger(curr_chart,priceline,OBJPROP_COLOR,16777215);
            ObjectSetInteger(curr_chart,label,OBJPROP_COLOR,16777215); 
      } 
      else 
      {
         for(int r=0;r<fibarray;r++) // Dim 2 Loop
         {
            if(Period()<=PERIOD_H1) {
               for(int s=0;s<fibarray;s++) // Dim 3 Loop
               {
                  string label = lines[l][r][s].label;
                  string price = lines[l][r][s].price;
                  string priceline = DoubleToString(price,5);
                  string time = TimeCurrent()+ 5*PeriodSeconds();
                     ObjectCreate(curr_chart,priceline, OBJ_HLINE, 0, 0, price);
                     ObjectCreate(curr_chart,label, OBJ_TEXT, 0, time, price);
                     ObjectSetString(curr_chart,label,OBJPROP_TEXT,label);
                     ObjectSetInteger(curr_chart,label,OBJPROP_FONTSIZE,8);
                     if(StringFind(label,"D3:0.0%",0)==-1) // highlight dim transition
                     {
                        ObjectSetInteger(curr_chart,priceline,OBJPROP_COLOR,16777215);
                     } else {
                        ObjectSetInteger(curr_chart,priceline,OBJPROP_COLOR,12378238);
                     }
                     ObjectSetInteger(curr_chart,label,OBJPROP_COLOR,16777215);                 
               }
            } else if(Period()<PERIOD_W1 && Period()>PERIOD_H1) {
                  // Only dim 2 lines for higher timeframes
                  string label = lines[l][r][0].label;
                  string price = lines[l][r][0].price;
                  string priceline = DoubleToString(price,5);
                  string time = TimeCurrent()+ 5*PeriodSeconds();
                     ObjectCreate(curr_chart,priceline, OBJ_HLINE, 0, 0, price);
                     ObjectCreate(curr_chart,label, OBJ_TEXT, 0, time, price);
                     ObjectSetString(curr_chart,label,OBJPROP_TEXT,label);
                     ObjectSetInteger(curr_chart,label,OBJPROP_FONTSIZE,8);
                     if(StringFind(label,"D2:0.0%",0)==-1) // highlight dim transition
                     {
                        ObjectSetInteger(curr_chart,priceline,OBJPROP_COLOR,16777215);
                     } else {
                        ObjectSetInteger(curr_chart,priceline,OBJPROP_COLOR,12378238);
                     }
                     ObjectSetInteger(curr_chart,label,OBJPROP_COLOR,16777215);      
            } else {
                  // Only dim 1 lines for higher timeframes
                  string label = lines[l][0][0].label;
                  string price = lines[l][0][0].price;
                  string priceline = DoubleToString(price,5);
                  string time = TimeCurrent()+ 5*PeriodSeconds();
                     ObjectCreate(curr_chart,priceline, OBJ_HLINE, 0, 0, price);
                     ObjectCreate(curr_chart,label, OBJ_TEXT, 0, time, price);
                     ObjectSetString(curr_chart,label,OBJPROP_TEXT,label);
                     ObjectSetInteger(curr_chart,label,OBJPROP_FONTSIZE,8);
                     ObjectSetInteger(curr_chart,priceline,OBJPROP_COLOR,16777215);
                     ObjectSetInteger(curr_chart,label,OBJPROP_COLOR,16777215);              
            }         
         }
      }
   }
   Print("Finished drawing all lines to the chart...");
      
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
     ArrayFree(lines);
     CleanChart();
}

void OnTick()
{

   
}

// Global Functions -------------------+

int error()
{
   Print("Error: ", GetLastError());
   return 0;
}
int CleanChart()
{
   int obj_total = ObjectsTotal(curr_chart,-1,-1);
   for(int i = obj_total - 1;i >= 0;i--)
   {
      string label = ObjectName(curr_chart,i,-1,-1);
      ObjectDelete(curr_chart,label);
   }
   // Print("Total drawn Objects to chart after deletion: "+obj_total);
   return 0;
}