//+------------------------------------------------------------------+
//|                                                    WorkerOne.mq4 |
//|                                                          Avluent |
//|                                          https://www.avluent.com |
//+------------------------------------------------------------------+

// Preprocessor directives
#property copyright "Jos Avezaat"
#property link      "https://www.avluent.com"
#property version   "0.04"
#property description "Selection of best perfoming symbols based on trend and volume"
#property strict

// Includes
#include <stdlib.mqh>

//----- Input variables ----- \\

uint TargetDay = 8; // The day at which the trades should be started
uint TargetHour = 14; // The hour at which the trades should be started
uint TargetMinute = 14; // The minutes of hour at which the trades should be started
uint trendThreshold = 10; // At what deviation from zero is a trend a trend (in %)?

//----- Main Structures ----- \\
struct symbolPriceData {
   int symbolId; // Marketwatch ID number
   string symbolName; // name of the symbol
   double allTimeHigh; // all time high
   double allTimeLow; // all time low
   double currentPrice; // current price
   double threeMonthClose; // close 3m ago
   double sixMonthClose; // close 6m ago
   double oneYearClose; // close 1y ago
   int trendDirection; // price trend (0-down/1-flat/2-up)
   double volatilityScore; // Volatility Score
   double demandPressure; // Demand pressure
   double supplyPressure; // Supply pressure
   double totalScore; // Total Score of Symbol (Trend+Volatility)
   int rankingPosition; // Postition on the trade Ranking
};

//----- Global Variables ----- \\

int symbolsTotal = SymbolsTotal(false); // number of Symbols in Total
string symbolNames[]; // Array with all Symbolnames
symbolPriceData MainSymbolData[]; // Main Array with all Symbol price data (see Struct)

//----- Event Handlers ----- \\
int OnInit()
{
   // Timer for fist run
   PrintFormat("Hi Jos, good to see you. I will start the first run for you now."); // Alert for First run
      
      // Set the proper Array Size for MainSymbolsData
      if (!ArrayResize(MainSymbolData,symbolsTotal,0)) { 
         int error=GetLastError();
         PrintFormat("Array Resize Failed: #%d[%s]", error, ErrorDescription(error));
      }
   
   uint firstRun = 1; // Set the first run time-out
   setTimer(firstRun); // Jump to the OnTimer Event
   
   // Close initialization 
   return(INIT_SUCCEEDED); // Close Initialization
}
void OnDeinit(const int reason)
{
   // When the program is closed
}

void OnTimer()
{
   // All Time Input Variables
   datetime CurrentTimeDate = TimeGMT(); // Current Time and Date (GMT)
   uint CurrentYear = TimeYear(CurrentTimeDate); // Current Year no.
   uint CurrentMonth = TimeMonth(CurrentTimeDate); // Current Month of Year no.
   uint CurrentDay = Day(); // Current Day of Month no.
   uint CurrentHour = TimeHour(CurrentTimeDate); // Current Hour in Time
   uint CurrentMinute = TimeMinute(CurrentTimeDate); // Current Minute in Time
   uint CurrentSeconds = TimeSeconds(CurrentTimeDate); // Current Minute in Seconds
   
   // +++ Timer +++
   //-- If today is not the first day of the month
   if (CurrentDay != TargetDay) {
      PrintFormat("Today is day "+CurrentDay+" of the month. You preferred Day "+TargetDay+". I will repeat my check in 24 hours.");// Log Entry to postpone
      uint nextRun=3624; // Reset the Timer in 24h
      setTimer(nextRun); // Run the timer
   } else {   
      //-- If today is the correct day of the Month  
       if ((CurrentHour <= TargetHour) && (CurrentMinute < TargetMinute)) { // Should we still be below or within the hour and min < Target min
            uint nextRun=((TargetHour-CurrentHour)*3600)+((TargetMinute-CurrentMinute)*60)-CurrentSeconds; // Hour + Minutes + Seconds added up
            PrintFormat("Today is Trading Day. I've reset the timer to "+nextRun+" seconds to accomodate to your requirements."); // Alert Reset Timer
            setTimer(nextRun); // Run the timer for the correct time
       }                 
      //-- Should the Trading Hour have passed
      if ((TargetHour<CurrentHour) || ((TargetHour==CurrentHour)&&(TargetMinute<CurrentMinute))) { 
         uint nextRun=((24-CurrentHour)*3600)-((60-CurrentMinute)*60)-CurrentSeconds;; // Hour + Minutes + Seconds added up
         PrintFormat("The hour of trading has already passed. I will reset the timer to midnight ("+nextRun+" seconds).");// Alert to postpone
         setTimer(nextRun); // Run the timer
      }
      //-- Exact Match for time and Date --> Main Program starts 
      if((CurrentHour == TargetHour) && (CurrentMinute == TargetMinute))  {
         PrintFormat("I've started the main program. Hang on to your hat!"); // Trigger main program
   // +++ End Timer +++
         
         // ++++++++++++++++++++++++ Main Program ++++++++++++++++++++++++++++++++++++ \\
         
                  
         // Load the symbol names
         if (!getSymbolNames()) { // Fetch all the symbol names from Marketwatch
            int error=GetLastError();
            PrintFormat("Error while loading symbol names: #%d[%s]", error, ErrorDescription(error));
         } else {
            PrintFormat("All symbolnames were successfully loaded from Marketwatch...");
         }
         
         /*
            // Open and Close all the charts in groups of 10 so that all data is available
            if(!cacheCharts()) {
               int error=GetLastError();
               PrintFormat("Error while caching the chart data: ", error, ErrorDescription(error));
            } else {
               PrintFormat("Done caching all chart data... Did you see the windows flashing..?");
            }      
         */
         
         // Load the Market data for all Symbols (For Loop)
         for (int i=0;i<symbolsTotal;i++) { // Loop through all Symbols and fill the struct
            
            // Set loop variables
            int id = i;
            string symbol = symbolNames[i];
               
               // Run the main function for retrieving data
               if (!loadSymbolData(id,symbol)) { // Execute the function to load data into the main Array
                  int error=GetLastError();
                  PrintFormat("Error loading the Symbol Data into the Array: #%d[%s]", error, ErrorDescription(error));
               }
               
         } // End Loop
         PrintFormat("Great! All Symbol Data was loaded into the main array..."); // Done loading all symbol data in the main Array
         
         // Money and Order Management
         
         
         
         // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ \\
         
      }
   }
   
   return; //-- Return Control back to Global Scope
}

//+++ ----- Global Functions ----- +++\\

//+++ Setting the timer to a specfic time (in seconds)
bool setTimer(uint seconds) { 
   if(!EventSetTimer(seconds)) { 
      int error=GetLastError();
      PrintFormat("EventSetTimer FAILED: #%d[%s]", error, ErrorDescription(error));
   }
   return true; // Exit Function
}

//+++ Getting all Symbol names from MarketWatch
bool getSymbolNames() {
   
   // Set function variables
   int total = symbolsTotal;
   string nameArray[];
   
   // Set the proper Array Size
   if (!ArrayResize(nameArray,total,0)) { 
      int error=GetLastError();
      PrintFormat("Array Resize Failed: #%d[%s]", error, ErrorDescription(error));
   } 
   
      // Loop through Marketwatch to store Symbolnames
      for (int i=0;i<total;i++) { 
         nameArray[i] = SymbolName(i,false);
      }
   
   // Copy Array into Global Array
   if (!ArrayCopy(symbolNames,nameArray,0,0,total)) { 
      int error=GetLastError();
      PrintFormat("Array Copy Failed: #%d[%s]", error, ErrorDescription(error));
   }
   
   // Exit Function
   return true; 
}

//+++ Building the struct with price information and placing them into MainSymbolData[]
bool loadSymbolData(int id, string symbol) { 
   
   //Let's go message
   PrintFormat("I just started working on "+symbol+".");
   
   // Current price
      double currentAskingPrice = MarketInfo(symbol,MODE_ASK);
      
         // Scan the closing prices for highest and lowest
         int bars = iBars(symbol,PERIOD_MN1); // Get total number of bars on the MN chart
         int athBar = iHighest(symbol,PERIOD_MN1,MODE_CLOSE,bars,0); // All time high (bar offset)
         int atlBar = iLowest(symbol, PERIOD_MN1,MODE_CLOSE,bars,0); // All time low (bar offset)
         double ath = iClose(symbol,PERIOD_MN1,athBar); // Get the all time high with the bar offset
         double atl = iClose(symbol,PERIOD_MN1,atlBar); // Get the all time low with the bar offset
      
      // Calculating price pressure
      double deviationRoof = ath - currentAskingPrice; // Deviation to the highest all time price
      double deviationFloor = currentAskingPrice - atl; // Deviation to the lowest all time price
      double FloorToRoof = ath - atl; // The room for price to move
      double demandPressure = (100 / FloorToRoof) * deviationRoof; // Calculates the Demand Pressure in %
      double supplyPressure = (100 / FloorToRoof) * deviationFloor; // Calculates the Supply Pressure in %
      
      // Retrieve last year's Tickrates 
      MqlRates PriceRates[]; // Declare the Array with Tickrates
      ArrayResize(PriceRates,12,0);
      
         // Copy last year's Tickrates into PriceRates[]
         if (!CopyRates(symbol,PERIOD_MN1,0,12,PriceRates)) { 
            int error=GetLastError();
            PrintFormat("Error with Tick Data: #%d[%s]", error, ErrorDescription(error));
         }
      
      // Check the number of bars that went into the array
      int priceRatesSize = ArraySize(PriceRates);
      printf("The number of candles in the monthly Char for "+symbol+" = "+priceRatesSize);
         
         // Print the fetched data in the Log
         for (int r=0;r<priceRatesSize;r++) {
             printf("Value of PriceRates for "+symbol+" is: "+PriceRates[r].close);
         }
         
      // Divide the number of candles to prevent array overflows
      int candleSixMonth = priceRatesSize / 2;
      int candleThreeMonth = priceRatesSize / 1.33;
      
      // Set variables for other functions   
      double oneYear = PriceRates[0].close; // Closing price from one year ago
      double sixMonth = PriceRates[candleSixMonth].close; // Closing price from six months ago
      double threeMonth = PriceRates[candleThreeMonth].close; // Closing price from three months ago

      // Trend direction,volatitiy and total score functions
      double volt = volatilityScore(oneYear,sixMonth,threeMonth,currentAskingPrice,FloorToRoof); // Volatility Scoring
      int trend = trendDirection(volt); // trend of the symbol (0-down/1-flat/2-up)
      double totalScore = overallScoring(trend,volt,demandPressure,supplyPressure);
      
      // Fill the Struct with all data gathered
      MainSymbolData[id].allTimeHigh = ath;
      MainSymbolData[id].allTimeLow = atl;
      MainSymbolData[id].currentPrice = currentAskingPrice;
      MainSymbolData[id].demandPressure = demandPressure;
      MainSymbolData[id].oneYearClose = oneYear;
      MainSymbolData[id].rankingPosition = NULL;
      MainSymbolData[id].sixMonthClose = sixMonth;
      MainSymbolData[id].supplyPressure = supplyPressure;
      MainSymbolData[id].symbolId = id;
      MainSymbolData[id].symbolName = symbol;
      MainSymbolData[id].threeMonthClose = threeMonth;
      MainSymbolData[id].totalScore = totalScore;
      MainSymbolData[id].trendDirection = trend;
      MainSymbolData[id].volatilityScore = volt;
      
         // Print the fetched data in the Log
         printf(symbol+" - MainSymbolData - ath: "+MainSymbolData[id].allTimeHigh);
         printf(symbol+" - MainSymbolData - atl: "+MainSymbolData[id].allTimeLow);
         printf(symbol+" - MainSymbolData - price: "+MainSymbolData[id].currentPrice);
         printf(symbol+" - MainSymbolData - demand: "+MainSymbolData[id].demandPressure);
         printf(symbol+" - MainSymbolData - 1y: "+MainSymbolData[id].oneYearClose);
         printf(symbol+" - MainSymbolData - ranking: "+MainSymbolData[id].rankingPosition);
         printf(symbol+" - MainSymbolData - 6m: "+MainSymbolData[id].sixMonthClose);
         printf(symbol+" - MainSymbolData - supply: "+MainSymbolData[id].supplyPressure);
         printf(symbol+" - MainSymbolData - id: "+MainSymbolData[id].symbolId);
         printf(symbol+" - MainSymbolData - name: "+MainSymbolData[id].symbolName);
         printf(symbol+" - MainSymbolData - 3m: "+MainSymbolData[id].threeMonthClose);
         printf(symbol+" - MainSymbolData - totalscore: "+MainSymbolData[id].totalScore);
         printf(symbol+" - MainSymbolData - trend: "+MainSymbolData[id].trendDirection);
         printf(symbol+" - MainSymbolData - volt: "+MainSymbolData[id].volatilityScore);
         
      //Take a pause young grasshopper
      Sleep(500);   
   
   return true;
}

//+++ Finding the Trend of the Symbol (0-down/1-flat/2-up)
int trendDirection(double volatility) { // Analyze the trend direction
   
   // Function variables
   uint longThreshold = trendThreshold;
   int shortThreshold = trendThreshold-(2*trendThreshold);
   int trend = NULL;
   
      if ((volatility > 0) && (volatility > longThreshold)) { // uptrend above threshold = long
         trend = 2;
      } 
         if ((volatility > 0) && (volatility < longThreshold)) { // trend up but below threshold = flat
            trend=1;
         }
            if (volatility == 0) { // no volatility = flat
               trend=1;
            }
         if ((volatility < 0) && (volatility > shortThreshold)) { // trend down but above threshold = flat
            trend=1;
         }
      if ((volatility < 0) && (volatility < shortThreshold)) { // trend down and below threshold = short
         trend=0;
      }      
   
   return trend;
}

//++ Volatility Score of Symbol
double volatilityScore(double oneYear,double sixMonth,double threeMonth,double askprice,double range) {

   double diffOneYear = 100/range*(askprice-oneYear); // Percentage Difference Year
   double diffSixMonth = 100/range*(askprice-sixMonth); // Percentage Difference six Months
   double diffThreeMonth = 100/range*(askprice-threeMonth);  // Percentage Difference three Months
   
   double score = ((diffOneYear*2)+(diffSixMonth*4)+(diffThreeMonth*8))/14;

   return score;
}

//++ Overall Scoring Algorithm
double overallScoring(int trend,double volt,double demand,double supply) { 
   
   double TrendScore = NULL;
   double DemandSupplyScore = NULL;
   
      // Give Bonus Points for the Trend being acknowledged
      switch(trend)
      {
         case 0: 
            TrendScore = -50.0;
            break;
         case 1:
            TrendScore = 0.0;
            break;
         case 2:
            TrendScore = 50.0;
            break;
      }
   
   // Check whether demand pressure (upward) pressure is higher then supply (downward) pressure
   if ((trend == 0) && (supply > demand)) { // Downtrend & Supply pressure is higher
      DemandSupplyScore=-25;
   }
   if ((trend == 2) && (supply < demand)) { // Uptrend & Demand pressure is higher
      DemandSupplyScore=25;
   }
   if (trend==1) { // Flat
      DemandSupplyScore=0;
   }   
      
   double totalScore = volt + TrendScore + DemandSupplyScore;
   return totalScore; // Return the Total Score
}

//++ Caching all Chart Windows
bool cacheCharts() {
   
   // Function Variables
   int counter = 0; 
   int limit = 10; // Limit of open charts per iteration
   
   // We start with a flush of all charts
   flushCharts();
   
   // Now we start openening all charts, 20 at a time
   for (int i=0;i<symbolsTotal;i++) {
      
      //Variables within the loop
      string symbol = symbolNames[i];
      
         if (counter < limit) {
            ChartOpen(symbol,PERIOD_MN1); // open the Chart
            counter++; // Iterate the counter
            Sleep(500);
         } else {
            Sleep(5000);
            flushCharts(); // Flush all charts
            counter = 0; // Reset the counter
            i--; // Take one iteration step back
         }   
      }   
   // We also end with a flush of all charts
   Sleep(5000);
   flushCharts();
   
   return true;
}   

//++ Closing all Chart Windows (Included in Cachecharts)
bool flushCharts() {
   
   long thisChartID = ChartID(); // Current Chart in Focus (last)
   long chartID = ChartFirst(); // First Chart in the Array
      
   int limit=100; // Limit number of Charts open
   
   // The loop for iterating through the chart windows
   for (int i = 0;i<limit;i++) {
      if (chartID == thisChartID) {  } // Not the current Chart
      else { // Close all other charts and iterate ChartID
         ChartClose(chartID);
      }
      
      chartID = ChartNext(chartID);
      if ( chartID < 0) {
         break;
      }      
   }
   return true;
} 