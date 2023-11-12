//+------------------------------------------------------------------+
//|                                           bilal_fairValueGap.mq5 |
//|                                    Copyright 2023, Novemind inc. |
//|                                         https://www.novemind.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Novemind inc."
#property link      "https://www.novemind.com"
#property version   "1.00"

int candles = 10;
const string sellObj = "sell", buyObj = "buy";


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
         if(StringFind(name,sellObj,0) >= 0 || StringFind(name,buyObj,0) >= 0)
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
      //========= Buy Fair Value Gap =========
      fairValueGap_Buy();

      //========= Sell Fair Value Gap =========
      fairValueGap_Sell();
     }
  }
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
double fairValueGap_Buy()
  {
   if(iLow(Symbol(),PERIOD_CURRENT,1) > iHigh(Symbol(),PERIOD_CURRENT,3))
     {
      if(iOpen(Symbol(),PERIOD_CURRENT,2) < iClose(Symbol(),PERIOD_CURRENT,2))
        {
         Alert("Buy Fair Value Gap Found "+Symbol());
         createObject(iTime(Symbol(),PERIOD_CURRENT,3),iHigh(Symbol(),PERIOD_CURRENT,3), iLow(Symbol(),PERIOD_CURRENT,1),POSITION_TYPE_BUY);
         return iLow(Symbol(),PERIOD_CURRENT,1);
        }
     }
   return 0;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double fairValueGap_Sell()
  {
   if(iLow(Symbol(),PERIOD_CURRENT,3) > iHigh(Symbol(),PERIOD_CURRENT,1))
     {
      if(iOpen(Symbol(),PERIOD_CURRENT,2) > iClose(Symbol(),PERIOD_CURRENT,2))
        {
         Alert("Sell Fair Value Gap Found "+Symbol());
         createObject(iTime(Symbol(),PERIOD_CURRENT,3),iLow(Symbol(),PERIOD_CURRENT,3), iHigh(Symbol(),PERIOD_CURRENT,1),POSITION_TYPE_SELL);
         return iHigh(Symbol(),PERIOD_CURRENT,1);
        }
     }
   return 0;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createObject(datetime time, double low,double high,ENUM_POSITION_TYPE type)
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
   Print("High : ",high," low: ",low);
   if(!ObjectCreate(0,objName,OBJ_RECTANGLE,0,time,high,time+(candles*PeriodSeconds(PERIOD_CURRENT)),low))
     {
      Print("Error in Creating Object: ",GetLastError());
     }
   else
     {
      Print("Object Created successfully: ",objName);
     }
   ObjectSetInteger(0,objName,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,objName,OBJPROP_FILL,true);
   ObjectSetInteger(0,objName,OBJPROP_BACK,true);

  }
//+------------------------------------------------------------------+
