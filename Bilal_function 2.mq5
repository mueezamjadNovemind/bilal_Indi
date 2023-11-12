//+------------------------------------------------------------------+
//|                                              bilal_Functions.mq5 |
//|                                    Copyright 2023, Novemind inc. |
//|                                         https://www.novemind.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Novemind inc."
#property link      "https://www.novemind.com"
#property version   "1.00"
input int               candles     = 6;                 // Candle Count
input ENUM_TIMEFRAMES   linesTF     = PERIOD_CURRENT;    // Lines Timeframe
const string highObj  = "High",lowObj  = "Low", checked = "checked";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

//---
   return(INIT_SUCCEEDED);
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
   if(newBar())
     {
      recenHigh();
      recenLow();
      markNewHighsLows();
     }
  }
//+------------------------------------------------------------------+
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void recenHigh()
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

            //if(prevTime == 0 || currTime >= prevTime)
              {
               //prevTime  = currTime;
               highValue = ObjectGetDouble(0,name,OBJPROP_PRICE,0);
               highObjName = name;
               if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
                 {
                  ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),PERIOD_CURRENT,1));
                 }
               if(highValue <=iClose(Symbol(),PERIOD_CURRENT,1) && highValue <= iHigh(Symbol(),PERIOD_CURRENT,1))
                 {
                  if(StringFind(ObjectGetString(0,highObjName,OBJPROP_TEXT),checked,0) < 0)
                    {
                     ObjectSetInteger(0,highObjName,OBJPROP_TIME,1,iTime(Symbol(),PERIOD_CURRENT,1));
                     ObjectSetString(0,highObjName,OBJPROP_TEXT,checked);
                     alert = true;
                    }

                 }
              }
           }
        }
     }
   if(alert)
      Alert("Sell Case Alert ");
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void recenLow()
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

           //if(prevTime == 0 || currTime >= prevTime)
              {
             //  prevTime  = currTime;
               lowValue = ObjectGetDouble(0,name,OBJPROP_PRICE,0);
               lowObjName = name;

               //Print("Low Value: ",lowValue," PreTime: ",prevTime);
               if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
                 {
                  ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),PERIOD_CURRENT,1));
                 }
               if(lowValue >= iClose(Symbol(),PERIOD_CURRENT,1) && lowValue > iLow(Symbol(),PERIOD_CURRENT,1))
                 {
                  if(StringFind(ObjectGetString(0,lowObjName,OBJPROP_TEXT),checked,0) < 0)
                    {
                     ObjectSetInteger(0,lowObjName,OBJPROP_TIME,1,iTime(Symbol(),PERIOD_CURRENT,1));
                     ObjectSetString(0,lowObjName,OBJPROP_TEXT,checked);
                     alert = true;
                    }

                 }
              }
           }
        }
     }
   if(alert)
      Alert("Buy Case Alert ");
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void markNewHighsLows()
  {

///============== Check High===================
   int midIndex = candles+1, countHigh = 0, countLow = 0;
//Print("Mid Index: ",midIndex);
   double midValueHigh = iHigh(Symbol(),linesTF,midIndex);
   double midValueLow  = iLow(Symbol(),linesTF,midIndex);
//Print("Mid Value: ",midValue," Mid Index: ",midIndex," Time: ",iTime(Symbol(),PERIOD_CURRENT,midIndex));

   for(int x = 1 ; x <= candles ; x ++)
     {
      if(midValueHigh >= iHigh(Symbol(),linesTF,midIndex+x) && midValueHigh >= iHigh(Symbol(),linesTF,midIndex-x))
        {
         countHigh++;
         //Print("Count ",count);
        }
      if(midValueLow <= iLow(Symbol(),linesTF,midIndex+x) && midValueLow <= iLow(Symbol(),linesTF,midIndex-x))
        {
         countLow++;
         //Print("Count ",count);
        }
     }
   if(countHigh == candles)
     {
      // Print(count," == ",candles);
      createObject(iTime(Symbol(),linesTF,midIndex),midValueHigh,true);
     }
   if(countLow == candles)
     {
      // Print(count," == ",candles);
      createObject(iTime(Symbol(),linesTF,midIndex),midValueLow,false);
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createObject(datetime time, double price,bool high)
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

   if(!ObjectCreate(0,objName,OBJ_TREND,0,time,price,time+(candles*PeriodSeconds(PERIOD_CURRENT)),price))
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
