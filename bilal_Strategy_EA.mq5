//+------------------------------------------------------------------+
//|                                            bilal_Strategy_EA.mq5 |
//|                                    Copyright 2023, Novemind inc. |
//|                                         https://www.novemind.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Novemind inc."
#property link      "https://www.novemind.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
CTrade trade;

input string             str2        = "<><><><><> General Settings <><><><><>"; // _
input double             lotsize     = 0.01;                                     // Lot Size
input double             tpRR        = 1;                                        // Takeprofit Risk to Reward
input int                magic_no    = 123;                                      // Magic Number
input int                candles_htf = 6;                                        // HTF Candle Count
input ENUM_TIMEFRAMES    linesTF_htf = PERIOD_H1;                                // Htf Lines Timeframe
input int                candles_ltf = 1;                                        // LTF Candle Count
input ENUM_TIMEFRAMES    linesTF_ltf = PERIOD_M5;                                // Ltf Lines Timeframe

const  string highObj  = "High",lowObj  = "Low", checked = "checked", sellObj = "fvg_sell", buyObj = "fvg_buy";;
double htf_High = 0, htf_Low = 0, ltf_High_fvg = 0, ltf_Low_fvg = 0;
datetime ltf_High_fvg_Time = 0, ltf_Low_fvg_Time = 0;
bool check_FVG_buy_SwingHigh = 0,check_FVG_sell_SwingLow = 0;
int candles = 10;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   trade.SetExpertMagicNumber(magic_no);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   trade.LogLevel(LOG_LEVEL_ALL);
   trade.SetAsyncMode(false);
   checkInHistory();
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|Checking the break in history                                     |
//+------------------------------------------------------------------+
void checkInHistory()
  {
   string highObjName   = "",    lowObjName = "";
   datetime highTime    = 0,    lowTime    = 0;
   double highValue     = 0,    lowValue   = 0;
   bool highFound       = false, lowFound   = false;

   for(int i = 1; i < Bars(Symbol(),linesTF_htf); i++)
     {
      //============== Previous High/Low ===================
      int midIndex = i+(candles_htf), countHigh = 0, countLow = 0;
      //Print("Mid Index: ",midIndex);
      double midValueHigh = iHigh(Symbol(),linesTF_htf,midIndex);
      double midValueLow  = iLow(Symbol(),linesTF_htf,midIndex);
      //Print(" Mid Index: ",midIndex," Time: ",iTime(Symbol(),linesTF_htf,midIndex));
      for(int x = 1 ; x <= candles_htf ; x ++)
        {
         if(midValueHigh >= iHigh(Symbol(),linesTF_htf,midIndex+x) && midValueHigh >= iHigh(Symbol(),linesTF_htf,midIndex-x))
           {
            //Print(x, " Left High: ",iHigh(Symbol(),linesTF_htf,midIndex+x)," < ",midValueHigh," > ",iHigh(Symbol(),linesTF_htf,midIndex-x)," RIGHT High");
            //Print("Time: Right: ",iTime(Symbol(),linesTF_htf,midIndex+x)," Left ",iTime(Symbol(),linesTF_htf,midIndex-x));
            //Print(" ");
            countHigh++;
           }
         if(midValueLow <= iLow(Symbol(),linesTF_htf,midIndex+x) && midValueLow <= iLow(Symbol(),linesTF_htf,midIndex-x))
           {
            countLow++;
            //Print("Low Count ",countLow);
           }
        }
      if(countHigh == candles_htf && highFound == false)
        {
         highFound = true;
         // Print(count," == ",candles);
         highTime = iTime(Symbol(),linesTF_htf,midIndex);
         Print("High Time: ",highTime);
         highObjName = createObject(highTime,midValueHigh,true);
         htf_High = midValueHigh;
         highValue = htf_High;

        }
      if(countLow == candles_htf && lowFound == false)
        {
         lowFound = true;
         // Print(count," == ",candles);
         lowTime = iTime(Symbol(),linesTF_htf,midIndex);
         lowObjName = createObject(lowTime,midValueLow,false);
         htf_Low = midValueLow;
         lowValue = htf_Low;

        }
      if(highFound && lowFound)
        {
         //Print("High Found: ",iTime(Symbol(),linesTF_htf,midIndex));
         break;
        }
     }

//============ Check High Sweep/Break ==================

   int ltfBar = iBarShift(Symbol(),linesTF_ltf,(highTime + PeriodSeconds(linesTF_htf)),false);
   for(int i = ltfBar; i > 0; i --)
     {
      if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
        {
         ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,i));
        }
      if(highValue >= iClose(Symbol(),linesTF_ltf,i) && highValue <= iHigh(Symbol(),linesTF_ltf,i))
        {
         if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
           {
            ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,i));
            ObjectSetString(0,highObjName,OBJPROP_TEXT,checked);
            //============ on Sweep High
            check_FVG_sell_SwingLow = true;
           }
        }
      else
         if(iClose(Symbol(),linesTF_ltf,i) > highValue)
           {
            if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
              {
               ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,i));
               ObjectSetString(0,highObjName,OBJPROP_TEXT,checked);
              }
           }
      //markNewHighsLows_LTF(true,true);
      fairValueGap_Sell(i);
     }

//============ Check Low Sweep/Break ==================
   ltfBar = iBarShift(Symbol(),linesTF_ltf,(lowTime + PeriodSeconds(linesTF_htf)),false);
   for(int i = ltfBar; i > 0; i --)
     {
      if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
        {
         ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,i));
        }
      if(lowValue <= iClose(Symbol(),linesTF_ltf,i) && lowValue > iLow(Symbol(),linesTF_ltf,i))
        {
         if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
           {
            ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,i));
            ObjectSetString(0,lowObjName,OBJPROP_TEXT,checked);
            //============ on Sweep Low
            // check_FVG_buy_SwingHigh = true;
           }
        }
      else
         if(iClose(Symbol(),linesTF_ltf,i) < lowValue)
           {
            if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
              {
               ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,i));
               ObjectSetString(0,lowObjName,OBJPROP_TEXT,checked);
              }
           }
      // markNewHighsLows_LTF(true,true);
      fairValueGap_Buy(i);
     }
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   string name = "";
   for(int i = ObjectsTotal(0)-1; i >= 0; i--)
     {
      name = ObjectName(0,i);
      if(ObjectGetInteger(0,name,OBJPROP_TYPE) == OBJ_TREND)
        {
         if(StringFind(name,highObj,0) >= 0 || StringFind(name,lowObj,0) >= 0)
           {
            ObjectDelete(0,name);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   Comment("High: ",htf_High,"  Low:  ",htf_Low," Buy Swing High  ", check_FVG_buy_SwingHigh," Sell Swing Low ",check_FVG_sell_SwingLow);
//
   if(newBar_htf()) //Higher Timeframe NewBar
     {
      markNewHighsLows(); //==== Marking the New High Lows on Higher Timeframe
     }

   if(newBar_ltf()) //Lower Timeframe NewBar
     {
      checkHighSweepBreak_LTF();
      checkLowSweepBreak_LTF();
      markNewHighsLows_LTF(check_FVG_buy_SwingHigh,check_FVG_sell_SwingLow);
      fairValueGap_Sell(1);
      fairValueGap_Buy(1);
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|NewBar for Higher Timeframe                                       |
//+------------------------------------------------------------------+
bool newBar_htf()
  {
//--- memorize the time of opening of the last bar in the static variable
   static datetime last_time=0;
//--- current time
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),linesTF_htf,SERIES_LASTBAR_DATE);
   if(last_time!=lastbar_time)
     {
      //--- memorize the time and return true
      last_time=lastbar_time;
      Print(".... NewBar(HTF) .... ",last_time);
      return(true);
     }
//--- if we passed to this line, then the bar is not new; return false
   return(false);
  }

//+------------------------------------------------------------------+
//|NewBar for Lower Timeframe                                        |
//+------------------------------------------------------------------+
bool newBar_ltf()
  {
   static datetime last_time=0;
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),linesTF_ltf,SERIES_LASTBAR_DATE);
   if(last_time!=lastbar_time)
     {
      last_time=lastbar_time;
      Print(".... NewBar(LTF) .... ",last_time);
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|Define high/lows on Higher Timeframe                              |
//+------------------------------------------------------------------+
void markNewHighsLows()
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
      createObject(iTime(Symbol(),linesTF_htf,midIndex),midValueHigh,true);
      htf_High = midValueHigh;
     }
   if(countLow == candles_htf)
     {
      createObject(iTime(Symbol(),linesTF_htf,midIndex),midValueLow,false);
      htf_Low = midValueLow;
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|Create Lines on Higher Timeframe                                  |
//+------------------------------------------------------------------+
string createObject(datetime time, double price,bool high)
  {
   string objName = "";
   color clr;
   if(high)
     {
      objName = highObj+IntegerToString(time);
      clr = clrRed;
     }
   else
     {
      objName = lowObj+IntegerToString(time);
      clr = clrGreen;
     }
   Print("Time: ",time," Time2: ",time+(candles_htf*PeriodSeconds(linesTF_htf)));
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
   return "";
  }
//+------------------------------------------------------------------+

//======================= LTF Objects ================================
//+------------------------------------------------------------------+
//|Define the high/lows on Lower Timeframe                           |
//+------------------------------------------------------------------+
void markNewHighsLows_LTF(bool fvgHigh, bool fvgLow)
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
   if(countHigh == candles_ltf && fvgHigh)
     {
      Print("High Fvg: ");
      createObject_LTF(iTime(Symbol(),linesTF_ltf,midIndex),midValueHigh,true);
      ltf_High_fvg      = midValueHigh;
      ltf_High_fvg_Time = iTime(Symbol(),linesTF_ltf,midIndex);
     }
   if(countLow == candles_ltf && fvgLow)
     {
      Print("Low Fvg: ");
      createObject_LTF(iTime(Symbol(),linesTF_ltf,midIndex),midValueLow,false);
      ltf_Low_fvg = midValueLow;
      ltf_Low_fvg_Time = iTime(Symbol(),linesTF_ltf,midIndex);
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|Create Lines on Lower  Timeframe                                  |
//+------------------------------------------------------------------+
void createObject_LTF(datetime time, double price,bool high)
  {
   string objName = "";
   color clr;
   if(high)
     {
      objName = highObj+IntegerToString(time);
      clr = clrPink;
     }
   else
     {
      objName = lowObj+IntegerToString(time);
      clr = clrLime;
     }

   if(!ObjectCreate(0,objName,OBJ_TREND,0,time,price,time+(candles_ltf*PeriodSeconds(PERIOD_CURRENT)),price))
     {
      Print("Error in Creating Object: ",GetLastError());
     }
   else
     {
      Print("Object Created successfully: ",objName);
     }
   ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,objName,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,objName,OBJPROP_HIDDEN,false);
   ObjectSetInteger(0,objName,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,objName,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,objName,OBJPROP_RAY_RIGHT,false);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkHighSweepBreak_LTF()
  {
   bool alert = false;
   string name = "",highObjName = "";
   datetime prevTime = 0, currTime = 0;
   double highValue = 0;
   for(int i = ObjectsTotal(0)-1; i >= 0; i--)
     {
      name = ObjectName(0,i);
      if(ObjectGetInteger(0,name,OBJPROP_TYPE) == OBJ_TREND)
        {
         if(StringFind(name,highObj,0) >= 0)
           {
            currTime = (datetime)ObjectGetInteger(0,name,OBJPROP_TIME,0);
            if(currTime > prevTime)
              {
               prevTime  = currTime;
               highValue = ObjectGetDouble(0,name,OBJPROP_PRICE,0);
               highObjName = name;
               if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
                 {
                  ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,1));
                 }
               if(highValue >= iClose(Symbol(),linesTF_ltf,1) && highValue <= iHigh(Symbol(),linesTF_ltf,1))
                 {
                  if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
                    {
                     ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,1));
                     ObjectSetString(0,highObjName,OBJPROP_TEXT,checked);
                     check_FVG_sell_SwingLow = true;
                    }
                 }
               else
                  if(iClose(Symbol(),linesTF_ltf,1) >= highValue)
                    {
                     if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
                       {
                        ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,1));
                        ObjectSetString(0,highObjName,OBJPROP_TEXT,checked);
                       }
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
void checkLowSweepBreak_LTF()
  {
   bool alert = false;
   string name = "",lowObjName = "";
   datetime prevTime = 0, currTime = 0;
   double lowValue = 0;
   for(int i = ObjectsTotal(0)-1; i >= 0; i--)
     {
      name = ObjectName(0,i);
      if(ObjectGetInteger(0,name,OBJPROP_TYPE) == OBJ_TREND)
        {
         if(StringFind(name,lowObj,0) >= 0)
           {
            currTime = (datetime)ObjectGetInteger(0,name,OBJPROP_TIME,0);
            if(currTime > prevTime)
              {
               prevTime  = currTime;
               lowValue = ObjectGetDouble(0,name,OBJPROP_PRICE,0);
               lowObjName = name;

               if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
                 {
                  ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,1));
                 }
               if(lowValue <= iClose(Symbol(),linesTF_ltf,1) && lowValue > iLow(Symbol(),linesTF_ltf,1))
                 {
                  if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
                    {
                     ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,1));
                     ObjectSetString(0,lowObjName,OBJPROP_TEXT,checked);
                     check_FVG_buy_SwingHigh = true;
                    }
                 }
               else
                  if(iClose(Symbol(),linesTF_ltf,1) < lowValue)
                    {
                     if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
                       {
                        ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),linesTF_ltf,1));
                        ObjectSetString(0,lowObjName,OBJPROP_TEXT,checked);
                       }
                    }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|Place Buy Trades                                                  |
//+------------------------------------------------------------------+
void placeBuyTrades()
  {
   double Ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double buySL = 0, buyTp = 0;

   if(trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,lotsize,Ask,buySL,buyTp,"Buy Trade Placed"))
     {
      Print("Buy Trade Placed");
     }
  }

//+------------------------------------------------------------------+
//|Place Sell Trades                                                 |
//+------------------------------------------------------------------+
void placeSellTrades()
  {
   double Bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   double sellSL = 0, sellTp = 0;

   if(trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,lotsize,Bid,sellSL,sellTp,"Sell Trade Placed"))
     {
      Print("Sell Trade PLaced ");
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double fairValueGap_Sell(int i)
  {
   if(/*iTime(Symbol(),PERIOD_CURRENT,i+2) > ltf_High_fvg_Time && */ltf_Low_fvg_Time != 0)
     {
      Print("Sell FVG: ",iTime(Symbol(),linesTF_ltf,i));
      if(iLow(Symbol(),linesTF_ltf,i) > iHigh(Symbol(),linesTF_ltf,i+2))
        {
         if(iOpen(Symbol(),linesTF_ltf,i+1) < iClose(Symbol(),linesTF_ltf,i+1))
           {
            Alert("Sell Fair Value Gap Found "+Symbol());
            createObject_fvg(iTime(Symbol(),linesTF_ltf,i+2),iHigh(Symbol(),linesTF_ltf,i+2), iLow(Symbol(),linesTF_ltf,i),POSITION_TYPE_SELL);
            return iLow(Symbol(),linesTF_ltf,i);
           }
        }
     }
   return 0;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double fairValueGap_Buy(int i)
  {
   if(/*iTime(Symbol(),PERIOD_CURRENT,i+2) > ltf_Low_fvg_Time && */ltf_High_fvg_Time != 0)
     {
      if(iLow(Symbol(),linesTF_ltf,i+2) > iHigh(Symbol(),linesTF_ltf,i))
        {
         if(iOpen(Symbol(),linesTF_ltf,i+1) > iClose(Symbol(),linesTF_ltf,i+1))
           {
            Alert("Sell Fair Value Gap Found "+Symbol());
            createObject_fvg(iTime(Symbol(),linesTF_ltf,i+2),iLow(Symbol(),linesTF_ltf,i+2), iHigh(Symbol(),linesTF_ltf,i),POSITION_TYPE_BUY);
            return iHigh(Symbol(),linesTF_ltf,i);
           }
        }
     }
   return 0;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createObject_fvg(datetime time, double low,double high,ENUM_POSITION_TYPE type)
  {
   string objName = "";
   color clr;
   if(type == POSITION_TYPE_SELL)
     {
      objName = sellObj+IntegerToString(time);
      clr = clrRed;
     }
   else
     {
      objName = buyObj+IntegerToString(time);
      clr = clrGreen;
     }
//Print("High : ",high," low: ",low);
   if(!ObjectCreate(0,objName,OBJ_RECTANGLE,0,time,high,time+(candles*PeriodSeconds(linesTF_ltf)),low))
     {
      Print("Error in Creating Object: ",GetLastError());
     }
   else
     {
      Print("Object Created successfully: ",objName);
      ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,objName,OBJPROP_FILL,true);
      ObjectSetInteger(0,objName,OBJPROP_BACK,true);
      if(type == POSITION_TYPE_SELL)
        {
         ltf_High_fvg_Time = 0;
         ltf_High_fvg = 0;
        }
      if(type == POSITION_TYPE_BUY)
        {
         ltf_Low_fvg_Time = 0;
         ltf_Low_fvg = 0;
        }
     }
  }
//+------------------------------------------------------------------+
