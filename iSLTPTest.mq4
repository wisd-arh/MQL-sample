//+------------------------------------------------------------------+
//|                                                    iSLTPTest.mq4 |
//|                      Copyright © 2010, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#include <stdlib.mqh>

#import "AskMath.dll"
  void MathInit();
  void MathDeinit();
  void D1Aprox(double& x[100], double& y[100], int n, double& k[1], double& b[1]);
#import



#define N 100000 
#define maxSpred 15

#define opBuy 1
#define opSell 2
#define opAll 0

// Сдвиг цены если Statement смоделирован в программе.
#define AskDBShift 1

extern double SLspeed = 2.5;

//--- input parameters
double BU_ordProfit = 5500; // 150;//165; //TP и SL в пунктах. БЕЗ учета спреда. 1pt = 1pt + spred.
extern double BU_ordLoss = 2000; // 170; //105;

double SL_ordProfit = 5500; //TP и SL в пунктах. БЕЗ учета спреда. 1pt = 1pt + spred.
extern double SL_ordLoss = 5500; 

//extern double tdelta=15;  

extern int MA_DerivativeDots = 3;
extern int MACD_DerivativeDots = 3;
//extern int MA_DerivativeDots5 = 6;
extern int MA_Period=3;

extern int SellEnable=1;
extern int BuyEnable=1;
extern int DropEnable=0;

extern int Rebuild = 0;
extern int TU = 0;
extern int TD = 0;
extern int TTunnel = 0;

extern int MTimeShift = 0; // Сдвиг = 1 если НЕ оригинальный MetaTraider Statement

extern int mxOrdCount = 1;

double ordProfit = 1.6;
double ordLoss = -6.6;   // = -(ordProfit + 2*spred)
//extern int t = 0;
//extern int r = 3600;

extern double tmp = 13;
extern int smax = 10;
//extern int ordTP = 55;
 
extern double MultexBuy = 0;
extern double MultexSell = 0;
datetime expTime;

extern int Tracking = 0;

int resCountBuy;
int resCountSell;
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+

static int Fields=19;
static int StopLoss=55;

double p[100];
extern int pC = 5;


int handle;
int handle2;
string str;

datetime DT[N];
string Dir[N];
double Lots[N];
double Prices[N];
double SLs[N];
double TPs[N];
double err[N];
double delta[N];
double polyK[N];
int c;
int cur, missing;
int m;

int hh, mm;
int all;

string _Symbol;
datetime ordTime;

double maxBid;
double minAsk;

int stathandle;


int d_day;
double d_k1, d_b1;
double d_k2, d_b2;
//***********************************************************************************************************
int init()
  {
//----

  int i;  

  d_day = 0;
//----
  stathandle=FileOpen("Stats2.txt",FILE_CSV|FILE_WRITE,9);
    if(stathandle<1)
      {
       Print("Файл Stats2.txt не обнаружен, последняя ошибка ", GetLastError());
       return(false);
      }
//  FileWrite(stathandle, "Day high#Day low#Open Price#Profit");
//  FileWrite(stathandle, "SpMoving#Open Price#Profit");
  FileWrite(stathandle, "N","Disp");

  if (pC > 100) { Print("pC: Out of range."); return(-1); }
  for (i=0; i<pC; i++) {
    p[i]=0;
  }
//----

  resCountBuy = 0;
  resCountSell = 0;

  _Symbol = Symbol();
  ordTime = 0;
  MathInit();

  handle=FileOpen("Statment.txt",FILE_CSV|FILE_READ,9);
  if(handle<1)
    {
     Print("Файл Statment.txt не обнаружен, последняя ошибка ", GetLastError());
     return(false);
    }

  
  for (i=0; i<Fields; i++) {
    str=FileReadString(handle);
  }

  c = 0;
  missing = 0;    
  m =0;
  maxBid = 0;
  minAsk = 0;

  while (!FileIsEnding(handle)) {
    str=FileReadString(handle);   
    if (StringLen(str) > 0) { 
      DT[c]=StrToTime(FileReadString(handle));    

      if (MTimeShift == 1) 
        if ((TimeDayOfYear(DT[c]) >= 86)&&(TimeDayOfYear(DT[c]) < 304)) {
          DT[c]=DT[c]+60*60;     
        }
      
      Dir[c]=FileReadString(handle);    
      Lots[c]=StrToDouble(FileReadString(handle));    
      str=FileReadString(handle);    
      Prices[c]=StrToDouble(FileReadString(handle));    
      SLs[c]=StrToDouble(FileReadString(handle));    
      TPs[c]=StrToDouble(FileReadString(handle));    

      str=FileReadString(handle);    
      str=FileReadString(handle);    
      str=FileReadString(handle);    
      str=FileReadString(handle);    
      str=FileReadString(handle);    
      str=FileReadString(handle);    

      err[c]=StrToDouble(FileReadString(handle));    
      if (!FileIsLineEnding(handle)) {  
        delta[c]=StrToDouble(FileReadString(handle));    
      } else 
        delta[c]=0.0;

      if (!FileIsLineEnding(handle)) {  
        str=FileReadString(handle);    
      }  
      if (!FileIsLineEnding(handle)) {  
        str=FileReadString(handle);    
      }  

      if (!FileIsLineEnding(handle)) {  
        polyK[c]=StrToDouble(FileReadString(handle));    
      } else 
        polyK[c]=0.0;
/*        
      if (c < 2) {  
        Alert(Err[c]);
        Alert(Delta[c]);
      }
*/      
      while (!(FileIsLineEnding(handle))) {
        str=FileReadString(handle);    
      } 
      c++;
    }      
  }
/*
  Alert(TimeToStr(DT[1]));
  Alert(Dir[1]);
  Alert(Lots[1]);
  Alert(Prices[1]);
  Alert(SLs[1]);
  Alert(TPs[1]);
 */ 
  all=c;
  cur=0;  
  FileClose(handle);

  if (Rebuild == 1) {
    handle=FileOpen("TUStatmentRebuild.txt",FILE_CSV|FILE_WRITE,9);
    if (handle < 1) {
       Print("Файл Statment.txt не обнаружен, последняя ошибка ", GetLastError());
       return(false);
    } else {
      FileWrite(handle, "Ticket","Open Time","Type","Size","Item","Price","S / L","T / P","Close Time","Price","Commission","Taxes","Swap","Profit","Error","Delta","UP","DOWN","K");
    } 

    handle2=FileOpen("TDStatmentRebuild.txt",FILE_CSV|FILE_WRITE,9);
    if (handle < 1) {
       Print("Файл Statment.txt не обнаружен, последняя ошибка ", GetLastError());
       return(false);
    } else {
      FileWrite(handle2, "Ticket","Open Time","Type","Size","Item","Price","S / L","T / P","Close Time","Price","Commission","Taxes","Swap","Profit","Error","Delta","UP","DOWN","K");
    } 
    
  }
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
  double tmis;
  
  CloseAll();
  MathDeinit();
  if (Rebuild == 1) {
    FileClose(handle);
    FileClose(handle2);
  }
  
  tmis = missing*100.0;
  tmis = tmis / all;
  Alert("missing="  + missing+ ", "+ DoubleToStr(tmis, 1)+"%");   
  Alert("Day="  + hh);   
  Alert("Hour="  + mm);   
  Alert("Last="  + cur);   
  Alert("All="+all);
  Alert("Spred="+DoubleToStr((Ask-Bid)/Point, 1)+"pt");
  
  FileClose(stathandle);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
  int tiket; 
  double curprice;
//  double delta;
  int op;
  datetime tmpd;
//----

//********************************************************************************************
//******ПОТИКОВЫЕ ОПЕРАЦИИ********************************************************************
//********************************************************************************************
  CheckOrdersState();
/*
  if (Tracking ==  1) {
    SellTracking();      
  }  
*/  
//  TrailingStop();

  
//  BidMax();

/*
  AskMin();
*/
/*   if ((GlobalUP()==1)||(GlobalDOWN()==1)) {
      ShiftPrice();
      p[0]=Ask;
   } 
 */ 

//********************************************************************************************
//********************************************************************************************
//********************************************************************************************

  if (cur < all) {
    while ((TimeDayOfYear(TimeLocal()) > TimeDayOfYear(DT[cur]))&&(cur < all)) {
      cur++;
      missing++;
    }

    while (((TimeDayOfYear(TimeLocal()) == TimeDayOfYear(DT[cur]))&&(TimeHour(TimeLocal()) > TimeHour(DT[cur])))&&(cur < all)) {
      cur++;
      missing++;
    }

    while (((TimeDayOfYear(TimeLocal()) == TimeDayOfYear(DT[cur]))&&(TimeHour(TimeLocal()) == TimeHour(DT[cur]))&&(TimeMinute(TimeLocal()) > TimeMinute(DT[cur])))&&(cur < all)) {
      cur++;
      missing++;
    } 
  }  
  
   
   hh = TimeDayOfYear(TimeLocal()); 
   mm = TimeHour(TimeLocal());
    
   if (cur < all) 
   if (TimeDayOfYear(TimeLocal()) == TimeDayOfYear(DT[cur])) 
   if (TimeHour(TimeLocal()) == TimeHour(DT[cur]))   
   if (TimeMinute(TimeLocal()) == TimeMinute(DT[cur]))   {

     if (StringFind(Dir[cur],"buy")>-1)  {  
       curprice = Ask;
//       price2 = Bid;
       op = OP_BUY;
     } else {
       curprice = Bid;
//       price2 = Ask; 
       op = OP_SELL; 
     }         
// При моделировании в программе - в сделке всегда цена BID     
// Если в базе сделано смещение на спред (2013-01-03)
     if (AskDBShift == 1) {
       curprice = Bid;
     }
     if ((MathAbs((curprice - Prices[cur]))) < 20*Point) {
        if (Rebuild == 1) {
           tmpd = DT[cur];
           if (MTimeShift == 1) 
             if ((TimeDayOfYear(tmpd) >= 86)&&(TimeDayOfYear(tmpd) < 304)) {
                tmpd = tmpd - 60*60;     
             }
             
           if (GlobalUP()==1) {      
             FileWrite(handle, "0", TimeToStr(tmpd), Dir[cur], Lots[cur], "eurusd", Prices[cur], "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
           }  
           if (GlobalDOWN()==1) {      
             FileWrite(handle2, "0", TimeToStr(tmpd), Dir[cur], Lots[cur], "eurusd", Prices[cur], "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0");
           }  
        }      
/*
        if (DropEnable == 1) {
          if (StringFind(Dir[cur],"buy")>-1)    
             CloseAll(opSell);       
          if (StringFind(Dir[cur],"sell")>-1)    
             CloseAll(opBuy);       
/*             
          if (StringFind(Dir[cur],"dropbuy")>-1)    
             CloseAll(opBuy);       
          if (StringFind(Dir[cur],"dropsell")>-1)    
             CloseAll(opSell);       
*/             
/*        }
*/        
//        if (DropEnable == 1)
//          if (StringFind(Dir[cur],"DROP")>-1) {   
//          if (StringFind(Dir[cur],"buy")>-1) {   
//            CloseAll();       
//          }
        
//        tiket = OrderSend(Symbol(), op, Lots[cur], curprice, 5, SLs[cur], TPs[cur]);

//        if (TimeHour(TimeLocal()) >= 8)
//        if (TimeHour(TimeLocal()) <=18)
/*//////////////
        if (err[cur] >= 7.47)
        if (err[cur] <= 10.842)  
        if (delta[cur] >= -24.984)        
        if (delta[cur] <= -10.516)        
        if (polyK[cur] >= -171.48)        
        if (polyK[cur] <= -45.781)        
        if (GlobalUP()==1)
*/        
/* 28/02        
        if (Err[cur] > 8.3)
//        if (Err[cur] > 5.5)  
        if (Err[cur] < 10.97)
*/        
/*
        if (Delta[cur] < -10.3)        
        if (polyK[cur] < -34)        
/*
        if (Err[cur] < 10.7)
        if (Delta[cur] < -10)        
*/        
        if (BuyEnable == 1)  
        if (StringFind(Dir[cur],"buy")>-1) 
        if (MaxOrderCount(OP_BUY) == 1)
//        if (ADXCheck() == 1)
//        if (SessionLock() == 1)
//        if (TimeMinute(TimeLocal()) != m)
//        if (SpredCheck() == 1)   // !
//        if ((TU == 0)||(H4pro(Ask)==1))    
//        if ((TU == 0)||(GlobalUP()==1))    
//        if ((TD == 0)||(GlobalDOWN()==1))
//        if (err[cur] < tdelta)
 
//        if (IsNewBar()) 
//        if (((High[1]-Low[1])/Point) > 22)
//        if (StringFind(Dir[cur],"buy")>-1) {   
// BUY OPEN
        {   
/// оригинальный
//            tiket = OrderSend(_Symbol, OP_BUY, 0.1, Ask, 5, NormalizeDouble(Bid - BU_ordLoss*Point, Digits), NormalizeDouble(Bid + BU_ordProfit*Point, Digits));
            tiket = OrderSend(_Symbol, OP_BUY, GetLotsBuy(), Ask, 5, NormalizeDouble(Bid - BU_ordLoss*Point, Digits), NormalizeDouble(Bid + BU_ordProfit*Point, Digits));
//            FileWrite(stathandle, tiket, DoubleToStr(delta[cur], 5));
            
// со статистикой
//            tiket = OrderSend(_Symbol, OP_BUY, 0.1, Ask, 5, NormalizeDouble(Bid - BU_ordLoss*Point, Digits), NormalizeDouble(Bid + BU_ordProfit*Point, Digits), DoubleToStr(iHigh(_Symbol, PERIOD_M1, 0)+Ask-Bid+Point, 6)+"#"+DoubleToStr(iLow(_Symbol, PERIOD_M1, 0)+Ask-Bid, 6));

//            tiket = OrderSend(_Symbol, OP_BUY, 0.1, Ask, 5, NormalizeDouble(Bid - BU_ordLoss*Point, Digits), NormalizeDouble(Bid + BU_ordProfit*Point, Digits));
//            tiket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 5, NormalizeDouble(Ask + SL_ordLoss*Point, Digits), NormalizeDouble(Ask - SL_ordProfit*Point, Digits));
/*
            ordTP = (Bid-iLow(NULL, PERIOD_M15, 1))/2/Point;
            if (ordTP < 55) { ordTP = 55; }
            ordTP = 55;
*/            
//            tiket = OrderSend(_Symbol, OP_BUY, 0.1, Ask, 5, NormalizeDouble(Bid-ordTP*Point, Digits), NormalizeDouble(Bid + ordTP*Point, Digits));
//            tiket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 5, NormalizeDouble(Ask + SL_ordLoss*Point, Digits), NormalizeDouble(Ask - SL_ordProfit*Point, Digits));
//            tiket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 5, NormalizeDouble(Ask + ordTP*Point, Digits), NormalizeDouble(Ask - ordTP*Point, Digits));
//            tiket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 5, NormalizeDouble(Ask + 55*Point, Digits), NormalizeDouble(Ask - ordTP*Point, Digits));
//            m = TimeMinute(TimeLocal());
  //        else 
  //           tiket = OrderSend(Symbol(), op, Lots[cur], curprice, 5,  NormalizeDouble(price2 + sl*Point, Digits), NormalizeDouble(price2 - tp*Point, Digits));

            if (tiket <= 0) {
              Alert("OrderSend: " + ErrorDescription(GetLastError()));
            }   
        }

        if (SellEnable == 1)  
        if (StringFind(Dir[cur],"sell")>-1)
        if (MaxOrderCount(OP_SELL) == 1)
//        if ((TimeLocal() - m) > t)
//        if (MaxOrderCount() == 1)
/*////////////
        if (TimeDayOfYear(TimeLocal()) > 20) 
//        if (Err[cur] < 12)
        if (err[cur] >= 9.171)
        if (err[cur] <= 20.452)  
        if (delta[cur] >= 0.497)        
        if (delta[cur] <= 48.995)        
        if (polyK[cur] >= 61.094)        
        if (polyK[cur] <= 236.445)        

        if (GlobalDOWN()==1)
*/

/*
28/02
        if (Err[cur] < 22.0)
        if (polyK[cur] < 279) 
*/               
        
//        if ((TU == 0)||(GlobalUP()==1))
//        if ((TD == 0)||(GlobalDOWN()==1))
//        if ((TTunnel == 0)||(SpTunnel(Bid - Multex*Point) > 0))
//        if ((TimeCurrent() - ordTime) > r) 

//        if (StringFind(Dir[cur],"sell")>-1) {   

// SELL OPEN        
        {   
//ориг           
//             tiket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 5, NormalizeDouble(Ask + SL_ordLoss*Point, Digits), NormalizeDouble(Ask - SL_ordProfit*Point, Digits));
             tiket = OrderSend(_Symbol, OP_SELL, GetLotsSell(), Bid, 5, NormalizeDouble(Ask + SL_ordLoss*Point, Digits), NormalizeDouble(Ask - SL_ordProfit*Point, Digits));
//             FileWrite(stathandle, tiket, DoubleToStr(delta[cur], 5));
//            tiket = OrderSend(_Symbol, OP_BUY, 0.1, Ask, 5, NormalizeDouble(Bid - BU_ordLoss*Point, Digits), NormalizeDouble(Bid + BU_ordProfit*Point, Digits));

//spmoving   tiket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 5, NormalizeDouble(Ask + SL_ordLoss*Point, Digits), NormalizeDouble(Ask - SL_ordProfit*Point, Digits), DoubleToStr(SpMoving(), 1));
//            tiket = OrderSend(_Symbol, OP_SELL, 0.1, Bid, 5, NormalizeDouble(Ask + SL_ordLoss*Point, Digits), NormalizeDouble(Ask - SL_ordProfit*Point, Digits), DoubleToStr(SpTunnel(Bid - 100*Point), 1));

//            m = TimeLocal();
//            ordTime = TimeCurrent();
//            tiket = OrderSend(_Symbol, OP_BUY, 0.1, Ask, 5, Bid - 2*MedH(), Ask + MedH());
           if (tiket <= 0) {
             Alert("OrderSend: " + ErrorDescription(GetLastError()));
           } 
        }  
       
        cur++;     
     }   

   } else // Не нашли подходящую цену.
      
     if (((TimeMinute(TimeLocal()) > TimeMinute(DT[cur]))&&(TimeHour(TimeLocal()) == TimeHour(DT[cur]))&&(TimeDayOfYear(TimeLocal()) == TimeDayOfYear(DT[cur])))||((TimeMinute(TimeLocal()) == 0)&&(TimeHour(TimeLocal()) > TimeHour(DT[cur]))&&(TimeDayOfYear(TimeLocal()) == TimeDayOfYear(DT[cur])))) {
        cur++;
        missing++;
//        FileWrite(stathandle, "Missing: "+DT[cur]);
     } 
      
   
  
//----
   return(0);
  }
//+------------------------------------------------------------------+

int G2_MA_IsUp(int Dots, int Shift=0, int _Period = 0) {
  double x[100], y[100];
  double rK, rB; // f(x)=rK*x + rB + eps;
  
  double s1, s2, s3, s4, s5, s6;
  int i;
  double t, alfa;
  datetime tm1, tm2; 

  if (Dots > 100) { return(0); }
  
  for (i=0; i<Dots; i++) {
    y[i] = 1000 * iMA(NULL, _Period, MA_Period, 0, MODE_SMA, PRICE_CLOSE, Dots-i-1+Shift); 
    x[i] = i;
  }
  
// Сдвигаем к 0 и умножаем на 1000, чтобы увеличить модуль значения.  
    
/*  t = y[0];  
  for (i=0; i<Dots; i++) {
    y[i] = (y[i]-t)*1000;
  }
*/  
  
  s1 = 0;
  s2 = 0;
  s3 = 0;
  s4 = 0;
  s5 = 0;
  s6 = 0;
  
  for (i=0; i<Dots; i++) {
    s1 = s1 + x[i]*x[i];
    s2 = s2 + y[i];
    s3 = s3 + x[i];
    s4 = s4 + x[i]*y[i];
  }
  s5 = Dots*s1;
  s6 = s3*s3;
  
  rB = (s1*s2-s3*s4)/(s5-s6);
  
  rK = (Dots*s4-s3*s2)/(s5-s6);  

//  alfa = MathArctan(rK)*180/3.14;

/*
  Alert("-----------");
  Alert(_Period);
    for (i=0; i<Dots; i++) {
      Alert(y[i]);
    }
    
  Alert("-----------");

  Alert("rK"  + rK);
  Alert(alfa);
*/
/*  if (alfa > 0) { return(1); }
  
  if (alfa < -0) { return(-1); }
*/
  if (rK > 0) { return(1); }
  
  if (rK < -0) { return(-1); }

  Alert("G2_MA_IsUp::rK=0.0");
  return(0);  
}


int G2_MA_IsDown(int Dots, int Shift=0, int _Period = 0) {
  if (G2_MA_IsUp(Dots, Shift, _Period) == -1) {
    return(1); 
  }
  return(0);
}


int GlobalUP() {
  double x[100], y[100];
//  double x2[100], y2[100];
  int i, n; 
  double k[1], b[1];

//  double k2[1], b2[1];
/*
  int MA_Shift;
  
  MA_Shift = MA_DerivativeDots;
(G2_MA_IsUp(MA_DerivativeDots, MA_Shift, PERIOD_M1)==1)&&
 &&(G2_MA_IsUp(3, 0, PERIOD_M30)==1)
 */ 

//  n = 10;
//  n = 12;
  n = pC;
  for (i=0; i < n; i++) {
    x[i] = i;
//    y[i] = iMA(_Symbol, NULL, 3, 0, MODE_EMA, PRICE_HIGH, n-i);
//    y[i] = iMA(_Symbol, NULL, t, 0, MODE_SMA, PRICE_WEIGHTED, n-i);
//    y[i] = iMA(_Symbol, NULL, t, 0, MODE_SMA, PRICE_CLOSE, n-i); // доказано оптимизацией PRICE_CLOSE + 12*M1
    //x2[i] = i;
//    y[i] = iVolume(_Symbol, PERIOD_M30, n-1-i);
//    y[i] = iMACD(_Symbol, PERIOD_M30, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, n-i-2);     
//      y[i] = 1000 * iMA(NULL, PERIOD_M30, MA_Period, 0, MODE_EMA, PRICE_CLOSE, n-i-1);

    y[i]=( iHigh(NULL, PERIOD_M1, n-i)+iLow(NULL, PERIOD_M1, n-i))/2;
//    y2[i]= iLow(NULL, PERIOD_M1, n-i);
  }
  k[0]=0;
  b[0]=0;
//  k2[0]=0; 
//  b2[0]=0;
  D1Aprox(x, y, n, k, b);

//  D1Aprox(x2, y2, n, k2, b2);
  
  
//  D1Aprox(x, p, pC, k, b);

//  if (iLow(Symbol(), PERIOD_D1, 0) > (iOpen(Symbol(), PERIOD_D1, 0) - 300*Point)) 
  if (k[0] < 0)
//  if (iSAR(_Symbol, NULL, 0.03, 0.1, 0) > Bid)

//  if (iSAR(_Symbol, NULL, 0.05, 0.1, 0) > Bid)
//  if (k2[0] > 0)
  
//  if ((G2_MA_IsUp(MA_DerivativeDots, 0, PERIOD_M1)==1)&&(G2_MA_IsUp(MA_DerivativeDots5, 0, PERIOD_M5)==1)) {
//  if (Bid < iOpen(Symbol(), PERIOD_D1, 0))//-100*Point) 
    
//    if (iMA(NULL, PERIOD_M5, 3, 0, MODE_EMA, PRICE_CLOSE, 0) > iMA(NULL, PERIOD_M5, 6, 0, MODE_EMA, PRICE_CLOSE, 0))
//    if (Hour() < 18) 
//      if (Bid > iSAR(Symbol(), PERIOD_M30, 0.03, 0.3, 0))
//  if (iVolume(_Symbol, PERIOD_M30, 2) < iVolume(_Symbol, PERIOD_M30, 1))

//     if ((G2_MA_IsUp(MA_DerivativeDots, 0, PERIOD_M30)==1)) 
     {
        return(1);    
      }
  return(0);


/*
  return ((G2_MA_IsUp(4, 0, PERIOD_M5)==1)&&(PriceAPX_UP(PriceAPXdots)));  
*/  
}

int GlobalDOWN() {
/*  double pOpen;

  pOpen = iOpen(Symbol(), PERIOD_D1, 0);
  if (Bid < pOpen) 
    if (iHigh(Symbol(), PERIOD_D1, 0) < (pOpen + 300*Point)) 
      if (Bid < iSAR(Symbol(), PERIOD_M30, 0.03, 0.3, 0))
        if ((G2_MA_IsDown(MA_DerivativeDots, 0, PERIOD_M30)==1)) 
        {
          return(1);    
        }
  return(0);
*/  
//  if (Bid < (iMA(_Symbol, PERIOD_M30, 13, 0, MODE_SMA, PRICE_CLOSE, 0) - 110*Point)) {
//    return(1&(((!GlobalUP())&1)&(SellAngle())));
//  }

  int res = 1;
  
//  if (SpMoving() > 440) {res = 0;}
  res = res & SellAngle();
  return (((!GlobalUP())&1)&res);
//  return(0); 
}


int MaxOrderCount(int Mode) {
  int i, orderCount, k;

  k = 0;  
  orderCount = OrdersTotal();

  for (i=0; i<orderCount; i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderType() == Mode) 
         if (OrderSymbol() == _Symbol) {
           k++;
         }
    }
  }  
  if (k < mxOrdCount) {
    return(1);
  } else 
    return(0);
}

void CheckOrdersState() {
  int i, orderCount;
  datetime orderdt;
  int minutes;
  
  double spred;
  

  spred = (Ask-Bid)/Point;
  orderCount = OrdersTotal();
  
  
  for (i=0; i<orderCount; i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {

      if (OrderType() == OP_BUY) {
         ordProfit = MultexBuy*10*OrderLots();
         ordLoss = -(ordProfit + 2*spred*OrderLots());
      } else {
         ordProfit = MultexSell*10*OrderLots();
         ordLoss = -(ordProfit + 2*spred*OrderLots());
      }   

//     orderdt = OrderOpenTime();
//     minutes = (Day() - TimeDay(orderdt))*1440 + (Hour() - TimeHour(orderdt))*60 + (Minute() - TimeMinute(orderdt));      

//    if ((minutes > timeDelay)) 
    // Включено принудительное закрытие ордера, если он открыт более timeDelay минут.
//    if ((OrderProfit() >= ordProfit)) 
    if ((OrderProfit() >= ordProfit)||(OrderProfit() <= ordLoss))
//      if (OrderProfit() <= ordLoss)
    // Вкл. ПЗО по профит.
      { 
        if (OrderType() == OP_BUY) {
            if (OrderProfit() >= ordProfit) {
              resCountBuy++;
              if (resCountBuy > 0) {
                resCountBuy = 0;
              }  
            } else {
              resCountBuy--;
            }
        
//!          TradeWait();        
//          FileWrite(stathandle, OrderComment()+"#"+ DoubleToStr(OrderOpenPrice(), 6)+"#"+OrderProfit());
          OrderClose(OrderTicket(), OrderLots(), Bid, 5);
        } else {
            if (OrderProfit() >= ordProfit) {
              resCountSell++;
              if (resCountSell > 0) {
                resCountSell = 0;
              }  
            } else {
              resCountSell--;
            }
        
//!          TradeWait();        
           OrderClose(OrderTicket(), OrderLots(), Ask, 5);
//           FileWrite(stathandle, OrderComment()+"#"+ DoubleToStr(OrderOpenPrice(), 6)+"#"+OrderProfit());
//           FileWrite(stathandle, OrderProfit()+"#"+ DoubleToStr(OrderOpenPrice(), 6)+"#"+ DoubleToStr(iLow(NULL, PERIOD_D1, 1), 6)+"#"+ DoubleToStr(iHigh(NULL, PERIOD_D1, 1), 6));
        }  
      }     
/*      
    if (Dtunnel(OrderOpenPrice()+spred*Point+Multex*10*Point, 4) == 0)
      if (OrderProfit() <= ordLoss)
      { 
        if (OrderType() == OP_BUY) {
//!          TradeWait();        
          OrderClose(OrderTicket(), OrderLots(), Bid, 5);
        } else {
//!          TradeWait();        
           OrderClose(OrderTicket(), OrderLots(), Ask, 5);
        }  
      }     
*/      
      
    } 
  }
 
}


void TrailingStop() {
  int i;
  int index;
  int count;
  double TrStep;
  
  count = OrdersTotal();
// Шаг движения трейлинга, чтобы не перегружать сервер.
  TrStep = 20*Point;
  
  for (i=0; i<count; i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderType() == OP_BUY) {
        
        if (((Bid - BU_ordLoss*Point) - OrderStopLoss()) > TrStep)  
          OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid - BU_ordLoss*Point, Digits), NormalizeDouble(Bid + BU_ordProfit*Point, Digits),0);
        
              
      } else {
          if ((OrderStopLoss() - (Ask + SL_ordLoss*Point)) > TrStep)  
            OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask + SL_ordLoss*Point, Digits), NormalizeDouble(Ask - SL_ordProfit*Point, Digits),0);
          
      }
    }
  }
} 


int CloseAll(int op = opAll)
  {
   bool   result;
   int cmd, count, i;
//----
  
   count = OrdersTotal();
    
   for (i=0; i< count; i++)   
     {
//   while (OrderSelect(0,SELECT_BY_POS,MODE_TRADES))
      OrderSelect(0,SELECT_BY_POS,MODE_TRADES);
      cmd = OrderType();
      //---- first order is buy or sell
      if ((cmd==OP_BUY) || (cmd==OP_SELL))
        {
            result = true;
            if (cmd==OP_BUY)
             if ((op == opBuy)||(op == opAll)) 
               result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(), MODE_BID),5);
              
            if (cmd==OP_SELL)
              if ((op == opSell)||(op == opAll)) 
                result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(), MODE_ASK),5);
             

            if (result!=TRUE) 
              Alert("CloseAll::Error = ",GetLastError()); 
             
/*            else 
                error = 0;*/
  /*          if (error==135) {
              RefreshRates();
              i--;
//            else 
  //            break;
            }*/
        }
     }
//----
   return(0);
}


void BidMax() {

  if (maxBid < Bid ) { maxBid = Bid ; }
  else {
    if ((maxBid - Bid ) >= smax*Point) { 
      CloseAll();    
      maxBid = Bid;
    } 
  }
}


void AskMin() {

  if (minAsk > Ask ) { minAsk = Ask ; }
  else {
    if ((Ask - minAsk) >= smax*Point) { 
      CloseAll();    
      minAsk = Ask;
    } 
  }
}

void ShiftPrice() {
  for (int i=0; i< pC-1; i++) {
    p[pC-1-i]=p[pC-1-i-1];
  }
  p[0]=0;
}

bool IsNewBar() {
    if (Period() != PERIOD_M1) {
      Alert("IsNewBar::Period wrong.");
    }
   if (expTime==Time[0]) {
      return (false);
   }
   expTime=Time[0];
   return (true);
}

int OpenOrdersCount() {

  int count = OrdersTotal();
  int res=0;

  for (int i=0; i< count; i++) {
    if  (OrderSelect(i,SELECT_BY_POS,MODE_TRADES))  
      if (OrderSymbol() == _Symbol) {
        res++;  
      }  
  }
  return(res);
}

int H4pro(double price) {
  
  int i;
  double h[5];
  double l[5];
  double cdelta;  
  double pos;
  
  int n=5;
  int posmax=7;

  for (i = 0; i < n; i++) {
    h[i]= iHigh(_Symbol, PERIOD_H1, i)+Ask-Bid+Point;
    l[i]= iLow(_Symbol, PERIOD_H1, i)+Ask-Bid;
    
  }
  
  for (i = 1; i < n; i++) {
    if (h[i] > h[0]) { h[0] = h[i]; }
    if (l[i] < l[0]) { l[0] = l[i]; }
  }
  

  cdelta = (h[0]-l[0])/10.0;
  
  pos = MathRound((price - l[0])/cdelta);

  if (pos < posmax) { return(1); }
  else return(0);
}


int SpredCheck() {
  if (((Ask-Bid)/Point) <= maxSpred) {
    return(1);  
  } else return(0);
}

int SellAngle() {
  double x[30], y[30];
  int i, n; 
  double k[1], b[1];
  double alpha;

  n = 12;
  for (i=0; i < n; i++) {
    x[i] = i;
    y[i]=(iHigh(NULL, PERIOD_M1, n-i)+iLow(NULL, PERIOD_M1, n-i))/2;
  }

  k[0]=0;
  b[0]=0;
  D1Aprox(x, y, n, k, b);

//  if (k[0] < t)
  alpha = MathArctan(k[0])*180/3.1415;
  
  if (alpha < 0.0062) 
  {
    return(1);    
  }
  return(0);
}

void SellTracking() {
  
  int cc, i;
  double spred, price;
  double targetSL;
  double minProfit;
  double curProfit;
  double x[5];
  double y[5];
  double k[1], b[1];
  int points;
  double decx, alpha;
  
  cc = OrdersTotal();
  spred = (Ask-Bid)/Point;
  points = 3;
//  targetSL = 

//  minProfit = -(Multex + 2*spred/10);
  
  for (i=0; i<cc; i++) {
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if ((TimeCurrent() - OrderOpenTime()) > 120) {
        price = OrderOpenPrice();  
/*      curProfit = 0.1*(price - Ask)/Point;
      minProfit*Point*10 = Price - Ask; 
      Ask = price - minProfit
*/      
/////////        targetSL = price + (Multex + 2*spred/10)*Point*10;
      
        x[0]=0;
        x[1]=1;
        x[2]=2;   
/*        y[0]=High[2]+spred*Point;
        y[1]=High[1]+spred*Point;
        y[2]=Ask;
*/        
        y[0]=Low[2];
        y[1]=Low[1];
        y[2]=Bid;
        
        k[0]=0;
        b[0]=0;
        D1Aprox(x, y, points, k, b);
/* kx + b = targetSL
   x = (targetSL - b)/k. X>0;
*/    
/*        if (k[0] != 0) {
          decx = (targetSL - b[0])/k[0];
        } else decx = -1;

//        Alert(DoubleToStr(decx, 1));
        if (decx > 0) // Обязательно
          if (decx < SLspeed) 
*/        
        alpha = MathArctan(k[0])*180/3.1415;
  
        if (alpha > tmp) 
  
          {
//             Alert("cl" + OrderTicket());    
// Cмещается или нет??????
             OrderClose(OrderTicket(), OrderLots(), Ask, 5);  
             i--;
             cc--;
          }   
      }    
    }
  }
} 

double SpMoving() {

  int i;
  double res;

  res = 0;
  for (i=0; i< 5; i++) {
    res += (iClose(NULL, PERIOD_H1, i)-iOpen(NULL, PERIOD_H1, i))/Point;
  
  }
  return (res);
  
}

double SpTunnel(double tp) {
  double p = 0;
/*  
  if ((tp > iLow(NULL, PERIOD_M5, 1)) && (tp < iHigh(NULL, PERIOD_M5, 1))) {
    p+=0.1;
  }  
  if ((tp > iLow(NULL, PERIOD_M30, 1)) && (tp < iHigh(NULL, PERIOD_M30, 1))) {
    p+=0.1;
  }  
*/  
  if ((tp >= iLow(NULL, PERIOD_D1, 1)) && (tp <= iHigh(NULL, PERIOD_D1, 1))) {
    p+=0.1;
  }
 
  return (p);
}

int Dtunnel(double targetY, double targetX) {
  double xp;

  DayAprox(DayOfYear());  
  
  if (d_k1 != d_k2) {
    xp = (d_b2 - d_b1)/(d_k1 - d_k2);  
/*  
    Alert (DoubleToStr(F(targetX, k[0], b[0]), 5) + ":1");
    Alert (DoubleToStr(targetY, 5) + ":2");
    Alert (DoubleToStr(F(targetX, k2[0], b2[0]), 5) + ":3");
*/    
    if ((F(targetX, d_k1, d_b1) > targetY) && (F(targetX, d_k2, d_b2) < targetY)) {
      return(1);
    }
  }  

  return(0);
}

double F(double X, double K, double B) {
  
  return(K*X + B);

}

void DayAprox(int day) {
  
  double x[100], y[100];
  double x2[100], y2[100];
  int i, n; 

  double k[1], b[1];
  double k2[1], b2[1];


  if (d_day != day) {
  
    n = 3;
    for (i=0; i < n; i++) {
      x[i] = i;
      y[i]= iHigh(NULL, PERIOD_D1, n-i);
      x2[i] = i;
      y2[i]= iLow(NULL, PERIOD_D1, n-i);
    }


    k[0]=0;
    b[0]=0;
    k2[0]=0; 
    b2[0]=0;

    D1Aprox(x, y, n, k, b);
    D1Aprox(x2, y2, n, k2, b2);
    
    d_k1=k[0];
    d_b1=b[0];
    d_k2=k2[0];
    d_b2=b2[0];
    
    d_day = day;
  }

}

double SessionHigh() {

  double tmax=0;
  int i;
  
  for (i = 0; i < (TimeHour(TimeCurrent())-7); i++) {
    if (iHigh(_Symbol, PERIOD_H1, i) > tmax) {
      tmax = iHigh(_Symbol, PERIOD_H1, i);
    }
  }
  return (tmax);
}

int SessionLock() {

//  if ((Bid + 200*Point) < SessionHigh()) 

//  if ((iOpen(_Symbol, PERIOD_H1, 1)-Bid) < 300*Point)
  {
    return(1);
  }
  return(0);
}

int ADXCheck() {
  
  double tadx1;
  double tadx2;

  double tdi1;
  double tdi2; 
  
  tdi1 = iADX(NULL,PERIOD_M5,14,PRICE_HIGH,MODE_PLUSDI,0);
  tdi2 = iADX(NULL,PERIOD_M5,14,PRICE_HIGH,MODE_MINUSDI,0);
  
  tadx1 = iADX(NULL,PERIOD_M5,14,PRICE_HIGH,MODE_MAIN,0);  
  tadx2 = iADX(NULL,PERIOD_M5,14,PRICE_HIGH,MODE_MAIN,1);  

  if (tdi1 > tdi2)
  if (tadx1 > tadx2)
  if (tadx1 > tdi1)
  {
    return(1);
  }
  
 

  return(0);
}

double GetLotsBuy() {
  double l;
  double spr, n;
  
  
  spr = 0.1*(Ask-Bid)/Point;
  
  n = 0.1+(2*spr+MultexBuy)/MultexBuy;
  l = 0.1;

  
  if (resCountBuy < 0) {
   
    l = MathRound(0.1*MathPow(n, -resCountBuy)*10)*0.1;

/*    if (resCount < -4) {
      l = 8.1;   
      resCount--;
    }*/
    
  }
    
  return (l); 
  
}

double GetLotsSell() {
  double l;
  double spr, n;
  
  
  spr = 0.1*(Ask-Bid)/Point;
  
  n = 0.1+(2*spr+MultexSell)/MultexSell;
  l = 0.1;

  
  if (resCountSell < 0) {
    l = MathRound(0.1*MathPow(n, -resCountSell)*10)*0.1;
  }
    
  return (l); 
  
}