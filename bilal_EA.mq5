//+------------------------------------------------------------------+
//|                                                     bilal_EA.mq5 |
//|                                    Copyright 2023, Novemind inc. |
//|                                         https://www.novemind.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Novemind inc."
#property link      "https://www.novemind.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

#define orderNum 100

struct order
  {
   string            objectName_htf;
   bool              highObject_htf;
   bool              checkForSell;
   bool              lowObject_htf;
   bool              checkForBuy;
   datetime          objectTime_htf;
   datetime          objectSweepTime_htf;
   double            objectPrice_htf;

   string            objectName_ltf;
   bool              highObject_ltf;
   bool              lowObject_ltf;
   datetime          objectTime_ltf;
   datetime          objectSweepTime_ltf;
   datetime          objectShiftTime_ltf;
   double            objectPrice_ltf;
   string            fvg_objectName;
   bool              checkFVG;
   datetime          fvgTime;

   bool              buyPlace;
   bool              sellPlace;

                     order()
     {
      objectName_htf       = "";
      highObject_htf       = false;
      checkForSell         = false;
      lowObject_htf        = false;
      checkForBuy          = false;
      objectTime_htf       = 0;
      objectSweepTime_htf  = 0;

      objectName_ltf       = "";
      highObject_ltf       = false;
      lowObject_ltf        = false;
      objectTime_ltf       = false;
      objectSweepTime_ltf  = 0;
      objectShiftTime_ltf  = 0;
      fvg_objectName       = "";
      checkFVG             = false;

      buyPlace             = false;
      sellPlace            = false;
     }

  };
order od[orderNum];

input string             str2        = "<><><><><> General Settings <><><><><>"; // _
input double             lotsize     = 0.01;                                     // Lot Size
input double             tpRR        = 1;                                        // Takeprofit Risk to Reward
input int                magic_no    = 123;                                      // Magic Number
input int                candles_htf = 6;                                        // HTF Candle Count
input ENUM_TIMEFRAMES    linesTF_htf = PERIOD_H1;                                // Htf Lines Timeframe
input int                candles_ltf = 1;                                        // LTF Candle Count
input ENUM_TIMEFRAMES    linesTF_ltf = PERIOD_M5;                                // Ltf Lines Timeframe

int checkShift = 2;
const  string high_HTF  = "High_HTF",low_HTF  = "Low_HTF", checked = "checked", fvg_Sell = "fvg_sell", fvg_Buy = "fvg_buy",high_LTF  = "High_LTF",low_LTF  = "Low_LTF";
datetime expiry=D'2024.02.28 23:00:00';
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(TimeCurrent()>expiry)
     {
      Alert("EA IS Expired");
      ExpertRemove();
     }
   trade.SetExpertMagicNumber(magic_no);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   trade.LogLevel(LOG_LEVEL_ALL);
   trade.SetAsyncMode(false);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   if(newBar())
     {
      removeFromList();

      markNewHighsLows_HTF();       // Make New High Lows on Higher Timeframe
      //==================== Checking Sweeps of Higher Timeframe ============
      checkHighSweepBreak_HTF();
      checkLowSweepBreak_HTF();

      //====================
      markNewHighsLows_LTF();
      checkShift_LTF();
      checkFVG();
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool newBar()
  {
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   if(last_time!=lastbar_time)
     {
      //--- memorize the time and return true
      last_time=lastbar_time;
      Print(".... NewBar .... ",last_time);
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addToOrder(string htfName, datetime htf_Time, double htfPrice,bool highOnHTF, bool lowOnHTF)
  {
   for(int i=0; i<orderNum; i++)
     {
      if(od[i].objectName_htf == "")
        {
         od[i].objectName_htf          = htfName;
         od[i].objectTime_htf          = htf_Time;
         od[i].objectPrice_htf         = htfPrice;
         od[i].highObject_htf          = highOnHTF;
         od[i].lowObject_htf           = lowOnHTF;
         if(lowOnHTF)
            od[i].checkForBuy    = true;
         if(highOnHTF)
            od[i].checkForSell   = true;
         od[i].objectSweepTime_htf     = 0;


         od[i].objectName_ltf          = "";
         od[i].highObject_ltf          = false;
         od[i].lowObject_ltf           = false;
         od[i].objectTime_ltf          = 0;
         od[i].objectSweepTime_ltf     = 0;
         od[i].objectShiftTime_ltf     = 0;
         od[i].objectPrice_ltf         = 0;
         od[i].fvg_objectName          = "";
         od[i].buyPlace                = false;
         od[i].sellPlace               = false;
         od[i].fvgTime                 = 0;
         od[i].checkFVG                = false;

         Print(i, " Object Added to Struct: ",od[i].objectName_htf);
         break;
        }
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void removeFromList()
  {
   for(int i=0; i<orderNum; i++)
     {
      if(od[i].objectName_htf != "")
        {
         //if(od[i].buyPlaced || od[i].sellPlace)
         //   od[i].objectName_htf = "";

         if(od[i].highObject_htf && od[i].objectSweepTime_htf != 0 && iTime(Symbol(),linesTF_htf,1) > od[i].objectSweepTime_htf &&
            iHigh(Symbol(),linesTF_htf,1) >= od[i].objectPrice_htf)
           {
            Print("Removing Value from Struct: ",od[i].objectName_htf);
            od[i].objectName_htf = "";
           }

         if(od[i].lowObject_htf && od[i].objectSweepTime_htf != 0 && iTime(Symbol(),linesTF_htf,1) > od[i].objectSweepTime_htf &&
            iLow(Symbol(),linesTF_htf,1) <= od[i].objectPrice_htf)
           {
            Print("Removing Value from Struct: ",od[i].objectName_htf);
            od[i].objectName_htf = "";
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|Define high/lows on Higher Timeframe                              |
//+------------------------------------------------------------------+
void markNewHighsLows_HTF()
  {
///============== Check High===================
   int midIndex = candles_htf+1, countHigh = 0, countLow = 0;
   double midValueHigh = iHigh(Symbol(),linesTF_htf,midIndex);
   double midValueLow  = iLow(Symbol(),linesTF_htf,midIndex);

   for(int x = 1 ; x <= candles_htf ; x ++)
     {
      if(midValueHigh >= iHigh(Symbol(),linesTF_htf,midIndex+x) && midValueHigh >= iHigh(Symbol(),linesTF_htf,midIndex-x))
        {
         countHigh++;
        }
      if(midValueLow <= iLow(Symbol(),linesTF_htf,midIndex+x) && midValueLow <= iLow(Symbol(),linesTF_htf,midIndex-x))
        {
         countLow++;
        }
     }
   if(countHigh == candles_htf)
     {
      string name =  createObject_HTF(iTime(Symbol(),linesTF_htf,midIndex),midValueHigh,true);
      if(name !="")
         addToOrder(name,iTime(Symbol(),linesTF_htf,midIndex),midValueHigh,true,false);
     }
   if(countLow == candles_htf)
     {
      string name = createObject_HTF(iTime(Symbol(),linesTF_htf,midIndex),midValueLow,false);
      if(name !="")
         addToOrder(name,iTime(Symbol(),linesTF_htf,midIndex),midValueLow,false,true);
     }
  }
//+------------------------------------------------------------------+
//|Create Lines on Higher Timeframe                                  |
//+------------------------------------------------------------------+
string createObject_HTF(datetime time, double price,bool high)
  {
   string objName = "";
   color clr;
   if(high)
     {
      objName = high_HTF +IntegerToString(time);
      clr = clrRed;
     }
   else
     {
      objName = low_HTF +IntegerToString(time);
      clr = clrGreen;
     }
   if(ObjectFind(0,objName) < 0)
     {
      if(!ObjectCreate(0,objName,OBJ_TREND,0,time,price,time+(candles_htf*PeriodSeconds(linesTF_htf)),price))
        {
         Print("Error in Creating Object: ",GetLastError());
        }
      else
        {
         Print("Object Created successfully: ",objName,"  Value: ",price);

         ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
         ObjectSetInteger(0,objName,OBJPROP_STYLE,STYLE_SOLID);
         ObjectSetInteger(0,objName,OBJPROP_HIDDEN,false);
         ObjectSetInteger(0,objName,OBJPROP_WIDTH,2);
         ObjectSetInteger(0,objName,OBJPROP_RAY_LEFT,false);
         ObjectSetInteger(0,objName,OBJPROP_RAY_RIGHT,false);
         return objName;
        }
     }
   return "";
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkHighSweepBreak_HTF()
  {
   string highObjName = "";
   double highValue = 0;
   for(int i = 0 ; i < orderNum; i++)
     {
      if(od[i].objectName_htf != "" && od[i].objectSweepTime_htf == 0)
        {
         highObjName = od[i].objectName_htf;
         if(StringFind(highObjName,high_HTF,0) >= 0)
           {
            highValue = ObjectGetDouble(0,highObjName,OBJPROP_PRICE,0);
            if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
              {
               ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_htf,1));
              }
            if(highValue >= iClose(Symbol(),linesTF_htf,1) && highValue <= iHigh(Symbol(),linesTF_htf,1))
              {
               if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
                 {
                  ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_htf,1));
                  ObjectSetString(0,highObjName,OBJPROP_TEXT,checked);
                  od[i].objectSweepTime_htf = iTime(Symbol(),linesTF_htf,1);
                  od[i].lowObject_ltf = true;
                  Print("High Sweep Time: ", od[i].objectSweepTime_htf);
                 }
              }
            else
               if(iClose(Symbol(),linesTF_htf,1) >= highValue)
                 {
                  if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
                    {
                     ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_htf,1));
                     ObjectSetString(0,highObjName,OBJPROP_TEXT,checked);
                     Print("Close Above High. Removing Object From Struct: ", od[i].objectName_htf);
                     od[i].objectName_htf = "";
                    }
                 }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkLowSweepBreak_HTF()
  {
   string lowObjName = "";
   double lowValue = 0;
   for(int i = 0 ; i < orderNum; i++)
     {
      if(od[i].objectName_htf != "" && od[i].objectSweepTime_htf == 0)
        {
         lowObjName = od[i].objectName_htf;
         if(StringFind(lowObjName,low_HTF,0) >= 0)
           {
            lowValue = ObjectGetDouble(0,lowObjName,OBJPROP_PRICE,0);
            if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
              {
               ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_htf,1));
              }
            if(lowValue <=iClose(Symbol(),linesTF_htf,1) && lowValue >= iLow(Symbol(),linesTF_htf,1))
              {
               if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
                 {
                  ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_htf,1));
                  ObjectSetString(0,lowObjName,OBJPROP_TEXT,checked);
                  od[i].objectSweepTime_htf = iTime(Symbol(),linesTF_htf,1);
                  od[i].highObject_ltf = true;
                  Print("Low Sweep Time: ",iTime(Symbol(),linesTF_htf,1));
                 }
              }
            else
               if(iClose(Symbol(),linesTF_ltf,1) <= lowValue)
                 {
                  if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
                    {
                     ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_htf,1));
                     ObjectSetString(0,lowObjName,OBJPROP_TEXT,checked);
                     Print("Close Below Low Removing Object From Struct: ", od[i].objectName_htf);
                     od[i].objectName_htf = "";
                    }
                 }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//======================= LTF Objects ================================
//+------------------------------------------------------------------+
//|Define the high/lows on Lower Timeframe                           |
//+------------------------------------------------------------------+
void markNewHighsLows_LTF()
  {
///============== Check High===================
   int midIndex = candles_ltf+1, countHigh = 0, countLow = 0;
   double midValueHigh = iHigh(Symbol(),linesTF_ltf,midIndex);
   double midValueLow  = iLow(Symbol(),linesTF_ltf,midIndex);

   for(int x = 1 ; x <= candles_ltf ; x ++)
     {
      if(midValueHigh >= iHigh(Symbol(),linesTF_ltf,midIndex+x) && midValueHigh >= iHigh(Symbol(),linesTF_ltf,midIndex-x))
        {
         countHigh++;
        }
      if(midValueLow <= iLow(Symbol(),linesTF_ltf,midIndex+x) && midValueLow <= iLow(Symbol(),linesTF_ltf,midIndex-x))
        {
         countLow++;
        }
     }


   for(int i = 0; i < orderNum; i++)
     {
      if(od[i].objectName_htf != "" && od[i].objectSweepTime_htf != 0)
        {
         if(od[i].lowObject_ltf && countLow == candles_ltf && od[i].objectPrice_ltf == 0 &&
            iTime(Symbol(),linesTF_ltf,midIndex) > od[i].objectSweepTime_htf)
           {
            od[i].objectName_ltf = createObject_LTF(iTime(Symbol(),linesTF_ltf,midIndex),iTime(Symbol(),linesTF_ltf,0),midValueLow,false);
            od[i].objectPrice_ltf = midValueLow;
           }

         if(od[i].highObject_ltf && countHigh == candles_ltf && od[i].objectPrice_ltf == 0 &&
            iTime(Symbol(),linesTF_ltf,midIndex) > od[i].objectSweepTime_htf)
           {
            od[i].objectName_ltf = createObject_LTF(iTime(Symbol(),linesTF_ltf,midIndex),iTime(Symbol(),linesTF_ltf,0),midValueHigh,true);
            od[i].objectPrice_ltf = midValueHigh;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|Create Lines on Lower  Timeframe                                  |
//+------------------------------------------------------------------+
string createObject_LTF(datetime time,datetime time2,double price,bool high)
  {
   string objName = "";
   color clr;
   if(high)
     {
      objName = high_LTF+IntegerToString(time);
      clr = clrPink;
     }
   else
     {
      objName = low_LTF+IntegerToString(time);
      clr = clrLime;
     }

   if(!ObjectCreate(0,objName,OBJ_TREND,0,time,price,time2,price))
     {
      Print("Error in Creating Object: ",GetLastError());
     }
   else
     {
      Print("Object Created successfully: ",objName);

      ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,objName,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,objName,OBJPROP_HIDDEN,false);
      ObjectSetInteger(0,objName,OBJPROP_WIDTH,2);
      ObjectSetInteger(0,objName,OBJPROP_RAY_LEFT,false);
      ObjectSetInteger(0,objName,OBJPROP_RAY_RIGHT,false);
      return objName;
     }
   return "";
  }
//+------------------------

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkShift_LTF()
  {
   for(int i = 0; i < orderNum; i++)
     {
      if(od[i].objectName_htf != "")
        {
         if(od[i].objectSweepTime_htf != 0 && od[i].objectShiftTime_ltf == 0)  /////// ====== Sell
           {
            if(od[i].lowObject_ltf && od[i].objectPrice_ltf != 0)
              {
               if(od[i].objectPrice_ltf < iOpen(Symbol(),linesTF_ltf,1) && od[i].objectPrice_ltf > iClose(Symbol(),linesTF_ltf,1))
                 {
                  od[i].objectShiftTime_ltf = iTime(Symbol(),linesTF_ltf,1);
                  ObjectSetInteger(0,od[i].objectName_ltf,OBJPROP_TIME,iTime(Symbol(),linesTF_ltf,1));
                  od[i].checkFVG = true;
                  od[i].fvgTime  = iTime(Symbol(),linesTF_ltf,1);
                  od[i].sellPlace= true;
                  Print(i," Sell Shift ",od[i].objectName_htf);
                 }
              }

            if(od[i].highObject_ltf && od[i].objectPrice_ltf != 0 && od[i].objectShiftTime_ltf == 0) //========= Buy
              {
               if(od[i].objectPrice_ltf > iOpen(Symbol(),linesTF_ltf,1) && od[i].objectPrice_ltf < iClose(Symbol(),linesTF_ltf,1))
                 {
                  od[i].objectShiftTime_ltf = iTime(Symbol(),linesTF_ltf,1);
                  ObjectSetInteger(0,od[i].objectName_ltf,OBJPROP_TIME,iTime(Symbol(),linesTF_ltf,1));
                  od[i].checkFVG = true;
                  od[i].fvgTime  = iTime(Symbol(),linesTF_ltf,1);
                  od[i].buyPlace = true;
                  Print("Buy Shift ",od[i].objectName_htf);
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkFVG()
  {
   int i = 1;
   for(int x = 0; x < orderNum; x++)
     {
      if(od[x].objectName_htf != "" && od[x].checkFVG)
        {
         if(od[x].sellPlace)
           {
            if(iLow(Symbol(),linesTF_ltf,i+2) > iHigh(Symbol(),linesTF_ltf,i))
              {
               if(iOpen(Symbol(),linesTF_ltf,i+1) > iClose(Symbol(),linesTF_ltf,i+1))
                 {
                  Print("index: ",x," Name : ",od[x].objectName_htf," shift Time: ",od[x].objectShiftTime_ltf," sweep Time : ",od[x].objectSweepTime_htf);
                  int bar = iBarShift(Symbol(),linesTF_htf,od[x].objectSweepTime_htf);
                  Print("Bar: ",bar," Time: ",iTime(Symbol(),linesTF_ltf,bar)," Sell Open: ",iHigh(Symbol(),linesTF_ltf,i)," Sl :",iHigh(Symbol(),linesTF_htf,bar));
                  placeSellTrades(iHigh(Symbol(),linesTF_ltf,i),iHigh(Symbol(),linesTF_htf,bar));
                  od[x].objectName_htf = "";
                 }
              }
           }
         else
            if(od[x].buyPlace)
              {
               if(iLow(Symbol(),linesTF_ltf,i) > iHigh(Symbol(),linesTF_ltf,i+2))
                 {
                  if(iOpen(Symbol(),linesTF_ltf,i+1) < iClose(Symbol(),linesTF_ltf,i+1))
                    {
                     Print("index: ",x," Name : ",od[x].objectName_htf," shift Time: ",od[x].objectShiftTime_ltf," sweep Time : ",od[x].objectSweepTime_htf);
                     int bar = iBarShift(Symbol(),linesTF_htf,od[x].objectSweepTime_htf);
                     Print("Bar: ",bar," Time: ",iTime(Symbol(),linesTF_htf,bar),"Buy Open: ",iLow(Symbol(),linesTF_ltf,i)," Sl :",iLow(Symbol(),linesTF_htf,bar));
                     placeBuyTrades(iLow(Symbol(),linesTF_htf,i),iLow(Symbol(),linesTF_htf,bar));
                     od[x].objectName_htf = "";
                    }
                 }
              }
        }
     }
  }
//=============================== Place Trades ================================
//+------------------------------------------------------------------+
//|Place Buy Trades                                                  |
//+------------------------------------------------------------------+
void placeBuyTrades(double openPrice,double buySL)
  {
   double slDistance = openPrice - buySL;
   double buyTp = openPrice + tpRR*slDistance;
   if(trade.BuyLimit(lotsize,openPrice,Symbol(),buySL,buyTp,ORDER_TIME_GTC,0,"Buy limit"))
     {
      Print("Buy Limit Trade Placed ");
     }
   else
      Print("Error in BuyLimit ",GetLastError());
  }


//+------------------------------------------------------------------+
//|Place Sell Trades                                                 |
//+------------------------------------------------------------------+
void placeSellTrades(double openPrice,double sellSL)
  {
   double slDistance = sellSL - openPrice;
   double sellTp = openPrice - tpRR*slDistance;
   if(trade.SellLimit(lotsize,openPrice,Symbol(),sellSL,sellTp,ORDER_TIME_GTC,0,"Sell limit"))
     {
      Print("Sell Limit Trade Placed ");
     }
   else
      Print("Error in Sell Limit ",GetLastError());
  }
//+------------------------------------------------------------------+
