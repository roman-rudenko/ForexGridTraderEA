// ApM Modded v007 07/11/2012
#property copyright "Copyleft 2012"
#property link      "http://www.net"

string modver = "M7 (TLP public)";
extern bool ShowTradeComment = TRUE;
//extern bool RealtimeChartUpdate = FALSE;
extern double Lots = 0.01;
extern double MultiLotsFactor = 1.6;
extern double StepLots = 15.0;
extern double TakeProfit = 23.0;
extern bool UseTrailing = FALSE;
extern double TrailStart = 38.0;
extern double TrailStop = 18.0;
extern int MaxOpenOrders = 15;
extern bool SafeEquityStopOut = FALSE;
extern double SafeEquityRisk = 0.5;
extern double Slippage = 3.0;
extern int MagicNumber = 2024536;
extern bool FreezeAfterTP = FALSE;
extern bool Close_All_Orders = FALSE;
extern string TradeComment = "FXGT";
extern string ______________ = "Планировщик:";
extern int StartHour = 0;
extern int StartMinute = 0;
extern int StopHour = 0;
extern int StopMinute = 0;
extern int StartingTradeDay = 0;
extern int EndingTradeDay = 7;
/*extern*/ bool UseLotFix = TRUE;
extern double Grid_Ariphmetic = 0;
extern double Grid_Multiplier = 0;
extern double Grid_Ratio = 0;
extern string _____________ = "Тип торговли:";
extern int TradingType = 0;
   // 0 - Open Long and Short positins use magic number = MagicNumber (Long or Short position configuring in common options on expert property window)
   // 1 - Open only Long position use magic number - MagicNumber
   // 2 - Open only Short position use magic number - MagicNumber
   // 3 - Open Long and Short positions use magic for BUY - MagicNumber and magic for SELL - AdvMagicNumber
extern string ____________ = "Настройки разделённой торговли";
extern int AdvMagicNumber = 2024537;
extern double LotsSELL = 0.01;
extern double MultiLotsFactorSELL = 1.6;
extern double StepLotsSELL = 15.0;
extern double TakeProfitSELL = 23.0;
extern bool UseTrailingSELL = FALSE;
extern double TrailStartSELL = 38.0;
extern double TrailStopSELL = 18.0;
extern int MaxOpenOrdersSELL = 15;
bool CloseAllOrdersBeforeStart = FALSE;
double gd_188 = 48.0;
double gd_196 = 500.0;
bool gi_212 = TRUE;
bool gi_216 = FALSE;
int TypeCalculationLots = 1;
double LastBuyOrderPrice;
double LastSellOrderPrice;
double LotExp = 0.0;
double newProffit[] = {0,0};
double orderPrice[] = {0,0};
bool gi_HaveNewOpenOrders[] = {false,false};
double xTakeProfit[] = {0,0};
double xStepLots[] = {0,0};
int oldTime[] = {0,0};
int CurrentTime[] = {0,0};
int gi_300[] = {0,0};
double opLot[] = {0.0,0.0};
int gi_OrdersOpen[] = {0,0};
bool gi_328[] = {false,false};
bool gi_332[] = {false,false};
bool gi_336[] = {false,false};
bool modify[] = {false,false};
double maxAccEqu[] = {0.0,0.0};
double oldAccEqu[] = {0.0,0.0};
int TimeCloseOrderBUY = 0;
int TimeCloseOrderSELL = 0;
string gs_off_372 = "OFF";
string gs_live_380 = "REAL";
string stErr = "";
int xPoints;
int gStartMinutes, gStopMinutes;
double PipToTP, MaxDD = 0;
bool noInitErr = TRUE;
//int gi_312 = 0;
//double gd_232;
//double gd_280;
//double gd_320 = 0.0;
//bool gi_412 = TRUE;
//int gi_416 = 0;

bool IsTradeTime() {
  if (FreezeAfterTP) return(false);
  bool AllowTrade = true;
  gStartMinutes = 60 * StartHour + StartMinute;
  gStopMinutes = 60 * StopHour + StopMinute;
  int day = DayOfWeek();
  if (day < StartingTradeDay || day > EndingTradeDay) AllowTrade = false;
  int minuntes = 60 * TimeHour(TimeCurrent()) + TimeMinute(TimeCurrent());
  if (day <= StartingTradeDay && gStartMinutes >= minuntes) AllowTrade = false;
  if (day >= EndingTradeDay && gStopMinutes < minuntes) AllowTrade = false;
  return(AllowTrade);   
}   

int init() {
   xTakeProfit[0] = TakeProfit;
   xTakeProfit[1] = TakeProfitSELL;
   xStepLots[0] = StepLots;
   xStepLots[1] = StepLotsSELL;
   if (Digits == 2 || Digits == 4) xPoints = 1;
   else xPoints = 10;
//   gi_416 = AccountNumber();
//   gd_280 = MarketInfo(Symbol(), MODE_SPREAD) * Point * xPoints;
   switch (MarketInfo(Symbol(), MODE_MINLOT)) {
   case 0.001:
      LotExp = 3;
      break;
   case 0.01:
      LotExp = 2;
      break;
   case 0.1:
      LotExp = 1;
      break;
   case 1.0:
      LotExp = 0;
   }
   if (SafeEquityStopOut) gs_off_372 = "ON";
   if (IsDemo()) gs_live_380 = "DEMO";
   if (Period() != PERIOD_M1) {
      Print("FGT ERROR :: Invalid Timeframe, Please switch to M1.");
      Alert("FGT ERROR :: ", " Invalid Timeframe, Please switch to M1.");
      stErr = "Invalid Timeframe. FGT works on M1";
      noInitErr = FALSE;
   }
   return (0);
}

int deinit() {
   Comment("");
   if (ObjectFind("BG") >= 0) ObjectDelete("BG");
   if (ObjectFind("BG1") >= 0) ObjectDelete("BG1");
   if (ObjectFind("BG2") >= 0) ObjectDelete("BG2");
   if (ObjectFind("BG3") >= 0) ObjectDelete("BG3");
   if (ObjectFind("BG4") >= 0) ObjectDelete("BG4");
   if (ObjectFind("BG5") >= 0) ObjectDelete("BG5");
   if (ObjectFind("NAME") >= 0) ObjectDelete("NAME");
   return (0);
}

int start() {
   int ret;
   if (!noInitErr) return(0);
   ret = Processing(0,MagicNumber);
   if (ret>0) return(ret);
   if (TradingType==3) ret = ret && Processing(1,AdvMagicNumber);
   return(ret);
}

int Processing(int tt, int magic){


//   int lia_0[1];
//   int lia_4[1];
   int ticket;
   double buyLots;
   double sellLots;
   double bClose2;
   double bClose1;
   double xMultiLotsFactor;
   int xMaxOpenOrders;
   double xSL,xTP;
   int li_52;
   int i = 0;

   if (TradingType == 3 && tt == 1){
       xMultiLotsFactor=MultiLotsFactorSELL;
       xSL=StepLotsSELL;
       xTP=TakeProfitSELL;
       xMaxOpenOrders=MaxOpenOrdersSELL;
     } else{
         xMultiLotsFactor=MultiLotsFactor;
         xSL=StepLots;
         xTP=TakeProfit;
         xMaxOpenOrders=MaxOpenOrders;
       }
   if (Close_All_Orders == TRUE) {CloseAllOrders(magic); return (0);}
   
   if (UseTrailing && tt!=1) Trail(TrailStart, TrailStop, orderPrice[tt], magic);
     else if (UseTrailingSELL && tt==1) Trail(TrailStartSELL, TrailStopSELL, orderPrice[tt], magic);
   if (CloseAllOrdersBeforeStart) {
      if (TimeCurrent() >= CurrentTime[tt]) {
         CloseAllOrders(magic);
         Print("Closed All Trades Due To Server TimeOut");
      }
   }
   if (oldTime[tt] == Time[0]) return (0);
   oldTime[tt] = Time[0];
   double prf = CalcProffit(magic);
   if (SafeEquityStopOut) {
      if (prf < 0.0 && MathAbs(prf) > SafeEquityRisk / 100.0 * GetAccountEquity(magic, tt)) {
         CloseAllOrders(magic);
         Print("Closed All due to EQUITY STOP-OUT");
         modify[tt] = FALSE;
      }
   }
   gi_HaveNewOpenOrders[tt] = FALSE;
   gi_OrdersOpen[tt] = GetCountOrders(magic,tt);
   //if (gi_OrdersOpen[tt] == 0) gi_HaveNewOpenOrders[tt] = FALSE;
   for (i = OrdersTotal() - 1; i >= 0; i--) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
         if (OrderType() == OP_BUY) {
            gi_332[tt] = TRUE;
            gi_336[tt] = FALSE;
            buyLots = OrderLots();
            break;
         }
      }
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
         if (OrderType() == OP_SELL) {
            gi_332[tt] = FALSE;
            gi_336[tt] = TRUE;
            sellLots = OrderLots();
            break;
         }
      }
   }
   gi_328[tt] = FALSE;
   
   if (gi_OrdersOpen[tt] > 1 && UseLotFix) gi_300[tt] = gi_OrdersOpen[tt]-1;
   opLot[tt] = CalcLot(OP_SELL, magic, tt);
   
   // Grid Extender
   if (Grid_Ariphmetic + Grid_Multiplier > 0 && gi_OrdersOpen[tt] > 1) {
      if (Grid_Ariphmetic > 0) {
         xStepLots[tt] = xSL + (Grid_Ariphmetic * gi_300[tt]);
         xTakeProfit[tt] = xTP + (Grid_Ariphmetic * gi_300[tt]);
         if (Grid_Ratio > 0) xTakeProfit[tt] = xTakeProfit[tt] * Grid_Ratio;
                               } else {
      if (Grid_Multiplier > 0) {
         xStepLots[tt] = xSL * (Grid_Ariphmetic * gi_300[tt]);
         xTakeProfit[tt] = xTP * (Grid_Ariphmetic * gi_300[tt]);
         if (Grid_Ratio > 0) xTakeProfit[tt] = xTakeProfit[tt] * Grid_Ratio;}}
                                               } // Grid Extender
                                                  
   if (gi_OrdersOpen[tt] > 0 && gi_OrdersOpen[tt] <= xMaxOpenOrders) {
      RefreshRates();
      LastBuyOrderPrice = GetPriceLastOrder(OP_BUY, magic);
      LastSellOrderPrice = GetPriceLastOrder(OP_SELL, magic);
      li_52 = func1(gi_332[tt], gi_336[tt], Bid, Ask, LastBuyOrderPrice, LastSellOrderPrice, Point, xSL, xPoints);
      if (li_52 == 1) gi_328[tt] = TRUE;
      stErr = ReturnErrorMsg(3);
   }
   if (gi_OrdersOpen[tt] < 1) {
      gi_336[tt] = FALSE;
      gi_332[tt] = FALSE;
      gi_328[tt] = TRUE;
//      gd_232 = AccountEquity();
   }
   if (gi_328[tt]) {
      LastBuyOrderPrice = GetPriceLastOrder(OP_BUY, magic);
      LastSellOrderPrice = GetPriceLastOrder(OP_SELL, magic);
      if (gi_336[tt]) {
         if (gi_216) {
            CloseAllOrdersBS(false, true, magic);
            opLot[tt] = NormalizeDouble(xMultiLotsFactor * sellLots, LotExp);
         } else opLot[tt] = CalcLot(OP_SELL, magic, tt);
         if (gi_212) {
            gi_300[tt] = gi_OrdersOpen[tt];
            if (opLot[tt] > 0.0) {
               RefreshRates();
               ticket = fOrderSend(OP_SELL, opLot[tt], Slippage, 0, 0, TradeComment + "-" + gi_300[tt], magic, 0, HotPink, tt);
               if (ticket < 0) {
                  Print("Error: ", GetLastError());
                  return (0);
               }
               LastSellOrderPrice = GetPriceLastOrder(OP_SELL, magic);
               gi_328[tt] = FALSE;
               modify[tt] = TRUE;
            }
         }
      } else {
         if (gi_332[tt]) {
            if (gi_216) {
               CloseAllOrdersBS(true, false, magic);
               opLot[tt] = NormalizeDouble(xMultiLotsFactor * buyLots, LotExp);
            } else opLot[tt] = CalcLot(OP_BUY, magic, tt);
            if (gi_212) {
               gi_300[tt] = gi_OrdersOpen[tt];
               if (opLot[tt] > 0.0) {
                  ticket = fOrderSend(OP_BUY, opLot[tt], Slippage, 0, 0, TradeComment + "-" + gi_300[tt], magic, 0, Lime, tt);
                  if (ticket < 0) {
                     Print("Error: ", GetLastError());
                     return (0);
                  }
                  LastBuyOrderPrice = GetPriceLastOrder(OP_BUY, magic);
                  gi_328[tt] = FALSE;
                  modify[tt] = TRUE;
               }
            }
         }
      }
   }
   if (gi_328[tt] && gi_OrdersOpen[tt] < 1  && IsTradeTime()) {
      bClose2 = iClose(Symbol(), 0, 2);
      bClose1 = iClose(Symbol(), 0, 1);
      if ((!gi_336[tt]) && !gi_332[tt]) {
         gi_300[tt] = gi_OrdersOpen[tt];
         if (bClose2 > bClose1) {
            opLot[tt] = CalcLot(OP_SELL, magic, tt);
            if (opLot[tt] > 0.0) {
               ticket = fOrderSend(OP_SELL, opLot[tt], Slippage, 0, 0, TradeComment + " " + magic + "-" + gi_300[tt], magic, 0, HotPink, tt);
               if (ticket < 0) {
                  Print(opLot[tt], "Error: ", GetLastError());
                  return (0);
               }
               LastBuyOrderPrice = GetPriceLastOrder(OP_BUY, magic);
               modify[tt] = TRUE;
            }
         } else {
            opLot[tt] = CalcLot(OP_BUY, magic, tt);
            if (opLot[tt] > 0.0) {
               ticket = fOrderSend(OP_BUY, opLot[tt], Slippage, 0, 0, TradeComment + " " + magic + "-" + gi_300[tt], magic, 0, Lime, tt);
               if (ticket < 0) {
                  Print(opLot[tt], "Error: ", GetLastError());
                  return (0);
               }
               LastSellOrderPrice = GetPriceLastOrder(OP_SELL, magic);
               modify[tt] = TRUE;
            }
         }
      }
      if (ticket > 0) CurrentTime[tt] = TimeCurrent() + 60.0 * (60.0 * gd_188);
      gi_328[tt] = FALSE;
   }
   gi_OrdersOpen[tt] = GetCountOrders(magic, tt);
   orderPrice[tt] = 0;
   double summLots = 0;
   for (i = OrdersTotal() - 1; i >= 0; i--) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
         if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
            orderPrice[tt] += OrderOpenPrice() * OrderLots();
            summLots += OrderLots();
         }
      }
   }
   if (gi_OrdersOpen[tt] > 0) orderPrice[tt] = NormalizeDouble(orderPrice[tt] / summLots, Digits);
   if (modify[tt]) {
      for (i = OrdersTotal() - 1; i >= 0; i--) {
         OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
         if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_BUY) {
               newProffit[tt] = orderPrice[tt] + xTP * Point * xPoints;
//               gd_320 = orderPrice[tt] - gd_196 * Point * xPoints;
               gi_HaveNewOpenOrders[tt] = TRUE;
            }
         }
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_SELL) {
               newProffit[tt] = orderPrice[tt] - xTP * Point * xPoints;
//               gd_320 = orderPrice[tt] + gd_196 * Point * xPoints;
               gi_HaveNewOpenOrders[tt] = TRUE;
            }
         }
      }
   }
   if (modify[tt]) {
      if (gi_HaveNewOpenOrders[tt] == TRUE) {
         for (i = OrdersTotal() - 1; i >= 0; i--) {
            OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
            if (NormalizeDouble(newProffit[tt], Digits) == NormalizeDouble(OrderTakeProfit(), Digits)) continue;
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) OrderModify(OrderTicket(), orderPrice[tt], OrderStopLoss(), newProffit[tt], 0, Yellow);
            Sleep(3000);
            if (OrderTakeProfit() > 0) modify[tt] = FALSE;
         }
      }
   }
   ViewComment();
   return (0);
}

void ViewComment() {
   if (ShowTradeComment) {
      if (IsTesting() && !IsVisualMode()) return;
      if (ObjectFind("BG") < 0) {
         ObjectCreate("BG", OBJ_LABEL, 0, 0, 0);
         ObjectSetText("BG", "g", 195, "Webdings", Orange);
         ObjectSet("BG", OBJPROP_CORNER, 0);
         ObjectSet("BG", OBJPROP_BACK, TRUE);
         ObjectSet("BG", OBJPROP_XDISTANCE, 0);
         ObjectSet("BG", OBJPROP_YDISTANCE, 15);
      }
      if (ObjectFind("BG1") < 0) {
         ObjectCreate("BG1", OBJ_LABEL, 0, 0, 0);
         ObjectSetText("BG1", "g", 195, "Webdings", DimGray);
         ObjectSet("BG1", OBJPROP_BACK, FALSE);
         ObjectSet("BG1", OBJPROP_XDISTANCE, 0);
         ObjectSet("BG1", OBJPROP_YDISTANCE, 42);
      }
      if (ObjectFind("BG2") < 0) {
         ObjectCreate("BG2", OBJ_LABEL, 0, 0, 0);
         ObjectSetText("BG2", "g", 195, "Webdings", DimGray);
         ObjectSet("BG2", OBJPROP_CORNER, 0);
         ObjectSet("BG2", OBJPROP_BACK, TRUE);
         ObjectSet("BG2", OBJPROP_XDISTANCE, 0);
         ObjectSet("BG2", OBJPROP_YDISTANCE, 42);
      }
      if (ObjectFind("NAME") < 0) {
         ObjectCreate("NAME", OBJ_LABEL, 0, 0, 0);
         ObjectSetText("NAME", "FOREX GRID TRADER EA - " + Symbol(), 9, "Arial Bold", White);
         ObjectSet("NAME", OBJPROP_CORNER, 0);
         ObjectSet("NAME", OBJPROP_BACK, FALSE);
         ObjectSet("NAME", OBJPROP_XDISTANCE, 5);
         ObjectSet("NAME", OBJPROP_YDISTANCE, 23);
      }
      if (ObjectFind("BG3") < 0) {
         ObjectCreate("BG3", OBJ_LABEL, 0, 0, 0);
         ObjectSetText("BG3", "g", 95, "Webdings", DimGray);
         ObjectSet("BG3", OBJPROP_CORNER, 0);
         ObjectSet("BG3", OBJPROP_BACK, TRUE);
         ObjectSet("BG3", OBJPROP_XDISTANCE, 0);
         ObjectSet("BG3", OBJPROP_YDISTANCE, 110);
      }
      if (ObjectFind("BG5") < 0) {
         ObjectCreate("BG5", OBJ_LABEL, 0, 0, 0);
         ObjectSetText("BG5", "g", 195, "Webdings", DimGray);
         ObjectSet("BG5", OBJPROP_CORNER, 0);
         ObjectSet("BG5", OBJPROP_BACK, FALSE);
         ObjectSet("BG5", OBJPROP_XDISTANCE, 0);
         ObjectSet("BG5", OBJPROP_YDISTANCE, 110);
      }
      GetAccountInfo();
   }
}

double NormalizePrice(double price) {
   return (NormalizeDouble(price, Digits));
}

int CloseAllOrdersBS(bool onlyBUY, bool onlySELL, int magic) {
   int ret = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_BUY && onlyBUY) {
               RefreshRates();
               if (!IsTradeContextBusy()) {
                  if (!OrderClose(OrderTicket(), OrderLots(), NormalizePrice(Bid), 5, CLR_NONE)) {
                     Print("Error close BUY " + OrderTicket());
                     ret = -1;
                  }
               } else {
                  if (TimeCloseOrderBUY == iTime(NULL, 0, 0)) return (-2);
                  TimeCloseOrderBUY = iTime(NULL, 0, 0);
                  Print("Need close BUY " + OrderTicket() + ". Trade Context Busy");
                  return (-2);
               }
            }
            if (OrderType() == OP_SELL && onlySELL) {
               RefreshRates();
               if (!IsTradeContextBusy()) {
                  if (!(!OrderClose(OrderTicket(), OrderLots(), NormalizePrice(Ask), 5, CLR_NONE))) continue;
                  Print("Error Closing SELL Trade : " + OrderTicket());
                  ret = -1;
                  continue;
               }
               if (TimeCloseOrderSELL == iTime(NULL, 0, 0)) return (-2);
               TimeCloseOrderSELL = iTime(NULL, 0, 0);
               Print("Need to close SELL trade : " + OrderTicket() + ". Trade Context Busy");
               return (-2);
            }
         }
      }
   }
   return (ret);
}

double CalcLot(int cmd, int magic, int tt) {
   double lot,xlot,xMultiLotsFactor;
   int ocTime;
   if (TradingType==3 && tt==1){
         xMultiLotsFactor=MultiLotsFactorSELL;
         xlot = LotsSELL;
       } else {
           xlot = Lots;
           xMultiLotsFactor=MultiLotsFactor;
         }  
   switch (TypeCalculationLots) {
   case 0:
      lot = xlot;
      break;
   case 1:
      lot = NormalizeDouble(xlot * MathPow(xMultiLotsFactor, gi_300[tt]), LotExp);
      break;
   case 2:
      ocTime = 0;
      lot = xlot;
      for (int i = OrdersHistoryTotal() - 1; i >= 0; i--) {
         if (!(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))) return (-3);
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (ocTime < OrderCloseTime()) {
               ocTime = OrderCloseTime();
               if (OrderProfit() < 0.0) {
                  lot = NormalizeDouble(OrderLots() * xMultiLotsFactor, LotExp);
                  continue;
               }
               lot = xlot;
               continue;
               return (-3);
            }
         }
      }
   }
   if (AccountFreeMarginCheck(Symbol(), cmd, lot) <= 0.0) return (-1);
   if (GetLastError() == 134/* NOT_ENOUGH_MONEY */) return (-2);
   return (lot);
}

int GetCountOrders(int magic, int tt) {
   PipToTP = 0;
   int count = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic)
         if (OrderType() == OP_SELL || OrderType() == OP_BUY) count++;
         if (OrderTakeProfit() == 0) {modify[tt] = TRUE; gi_HaveNewOpenOrders[tt] = TRUE;}
         if (OrderTakeProfit() > 0.0 && PipToTP == 0) {
         if (OrderType() == OP_SELL) PipToTP = (Ask - OrderTakeProfit() ) / Point / xPoints;
         if (OrderType() == OP_BUY) PipToTP = (OrderTakeProfit() - Bid) / Point / xPoints;}
   }
   return (count);
}

void CloseAllOrders(int magic) {
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() == Symbol()) {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic) {
            if (OrderType() == OP_BUY) OrderClose(OrderTicket(), OrderLots(), Bid, Slippage, Blue);
            if (OrderType() == OP_SELL) OrderClose(OrderTicket(), OrderLots(), Ask, Slippage, Red);
         }
         Sleep(1000);
      }
   }
}

int fOrderSend(int cmd, double lot, int SP, int SL, int PF, string OC, int OMagic, int OE, color Color, int tt) {
   int ticket = 0;
   int errCode = 0;
   int i = 0;
   int TryCount = 100;
   bool doOpen;

   switch (cmd) {
   case OP_BUY:
      for (i = 0; i < TryCount; i++) {
         RefreshRates();
         if (TradingType==3 && tt==0) doOpen=true;
            else
              if (TradingType==3 && tt==1) doOpen=false;
                 else
                   if (TradingType==2) doOpen=false; else doOpen=true;
         if (doOpen) ticket = OrderSend(Symbol(), cmd, lot, Ask, SP, GetStopProffit(Bid, -SL), GetStopProffit(Ask, PF), OC, OMagic, OE, Color);
            else ticket=-1;
         errCode = GetLastError();
         if (errCode == 0/* NO_ERROR */) break;
         if (!((errCode == 4/* SERVER_BUSY */ || errCode == 137/* BROKER_BUSY */ || errCode == 146/* TRADE_CONTEXT_BUSY */ || errCode == 136/* OFF_QUOTES */))) break;
         Sleep(5000);
      }
      break;
   case OP_SELL:
      for (i = 0; i < TryCount; i++) {
         RefreshRates();
         if (TradingType==3 && tt==0) doOpen=false;
            else
               if (TradingType==3 && tt==1) doOpen=true;
                  else
                     if (TradingType==1) doOpen=false; else doOpen=true;
         if (doOpen) ticket = OrderSend(Symbol(), cmd, lot, Bid, SP, GetStopProffit(Ask, SL), GetStopProffit(Bid, -PF), OC, OMagic, OE, Color);
           else ticket=-1;
         errCode = GetLastError();
         if (errCode == 0/* NO_ERROR */) break;
         if (!((errCode == 4/* SERVER_BUSY */ || errCode == 137/* BROKER_BUSY */ || errCode == 146/* TRADE_CONTEXT_BUSY */ || errCode == 136/* OFF_QUOTES */))) break;
         Sleep(5000);
      }
   }
   return (ticket);
}

double GetStopProffit(double price, int pnt) {
   if (pnt == 0) return (0);
   return (price + pnt * Point * xPoints);
}

double CalcProffit(int magic) {
   double prf = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic)
         if (OrderType() == OP_BUY || OrderType() == OP_SELL) prf += OrderProfit();
   }
   return (prf);
}

void Trail(int Start, int End, double price, int magic) {
   int li_16;
   double SL;
   double nSL;
   if (End != 0) {
      for (int i = OrdersTotal() - 1; i >= 0; i--) {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
            if (OrderSymbol() == Symbol() || OrderMagicNumber() == magic) {
               if (OrderType() == OP_BUY) {
                  li_16 = NormalizeDouble((Bid - price) / Point / xPoints, 0);
                  if (li_16 < Start) continue;
                  SL = OrderStopLoss();
                  nSL = Bid - End * Point * xPoints;
                  if (SL == 0.0 || (SL != 0.0 && nSL > SL)) OrderModify(OrderTicket(), price, nSL, OrderTakeProfit(), 0, Aqua);
               }
               if (OrderType() == OP_SELL) {
                  li_16 = NormalizeDouble((price - Ask) / Point / xPoints, 0);
                  if (li_16 < Start) continue;
                  SL = OrderStopLoss();
                  nSL = Ask + End * Point * xPoints;
                  if (SL == 0.0 || (SL != 0.0 && nSL < SL)) OrderModify(OrderTicket(), price, nSL, OrderTakeProfit(), 0, Red);
               }
            }
            Sleep(1000);
         }
      }
   }
}

double GetAccountEquity(int magic, int tt) {
   if (GetCountOrders(magic, tt) == 0) maxAccEqu[tt] = AccountEquity();
   if (maxAccEqu[tt] < oldAccEqu[tt]) maxAccEqu[tt] = oldAccEqu[tt];
                   else maxAccEqu[tt] = AccountEquity();
   oldAccEqu[tt] = AccountEquity();
   return (maxAccEqu[tt]);
}

double GetPriceLastOrder(int tOper, int magic) {
   double OPrice;
   int ticket;
//   double oldOrderPrice = 0;
   int oldTicket = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() != Symbol() || OrderMagicNumber() != magic) continue;
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == magic && OrderType() == tOper) {
         ticket = OrderTicket();
         if (ticket > oldTicket) {
            OPrice = OrderOpenPrice();
//            oldOrderPrice = OrderPrice[tt];
            oldTicket = ticket;
         }
      }
   }
   return (OPrice);
}

void GetAccountInfo() {
   string ls_1 = "", ls_2 = "", ls_3 = "";
   string ls_0 = DoubleToStr(balanceDeviation(), 2);
   string str1,str2,str3,str4,str5,str6;
   switch (TradingType){
     case  3: {
                str1="Use double destinations";
                str2="OPEN BUY TRADES :                     " + DoubleToStr(OrdersCountByMagic(MagicNumber), 0);
                str3="\n";
                str4="OPEN SELL TRADES :                    " + DoubleToStr(OrdersCountByMagic(AdvMagicNumber), 0);
                str5="NEXT BUY LOT(S) :                     " + DoubleToStr(opLot[0], 2);
                str6="NEXT SELL LOT(S) :                     " + DoubleToStr(opLot[1], 2);
              } break;
     default: {
                str1="Use single destination";
                str2="OPEN TRADES :                         " + DoubleToStr(OrdersCountByMagic(MagicNumber), 0);
                str3="";
                str4="";
                str5="NEXT LOT(S) :                            " + DoubleToStr(opLot[0], 2);
                str6="";
              }
   }
   if (balanceDeviation() > MaxDD) MaxDD = balanceDeviation();
   ls_3 = "Margin Usage:                            " + DoubleToStr(100 - (AccountFreeMargin()/AccountBalance()*100),2) + "%\n";
   if (!IsTradeTime()) ls_1 = "New Trades disallowed by scheduler";
   if (FreezeAfterTP) ls_1 = "Freeze AfterTP Enabled";
   Comment("" 
      + "\n" 
      + "\n" 
      + "\n" 
      + "EXPERT VERSION: 1.0 " + modver
      + "\n" 
      + "====================================" 
      //+ "\n" 
      //+ "-----------------------------------------------------------------------------------" 
      //+ "\n" 
      //+ "AUTHENTICATION STATUS" 
      //+ "\n" 
      //+ "-----------------------------------------------------------------------------------" 
      //+ "\n" 
      //+ "STATUS MESSAGE:   " + gs_396 
      //+ "\n" 
      //+ "-----------------------------------------------------------------------------------" 
      + "\n" 
      + "ACCOUNT INFORMATION" 
      + "\n" 
      + "-----------------------------------------------------------------------------------" 
      + "\n" 
      //+ "Account Name:                " + AccountName() 
      //+ "\n" 
      + "Account Number:             " + AccountNumber() + " (" + gs_live_380 + ")"
      + "\n" 
      //+ "Account Type:                 " + gs_live_380 
      //+ "\n" 
      + "Account Leverage:           1:" + DoubleToStr(AccountLeverage(), 0) 
      + "\n" 
      + "Account Balance:             " + DoubleToStr(AccountBalance(), 2) 
      + "\n" 
      + "Account Equity:               " + DoubleToStr(AccountEquity(), 2) 
      + "\n" 
      + "Server Time:                   " + TimeToStr(TimeCurrent(), TIME_SECONDS)
      + "\n" 
      + "-----------------------------------------------------------------------------------" 
      + "\n" 
      + "TRADE INFORMATIONS " 
      + "\n" 
      + "------------------------------------------------------------------------------------" 
      + "\n" 
      + "SAFE EQUITY STOP OUT :        " + gs_off_372 + "  @ " + DoubleToStr(SafeEquityRisk*100, 2)  + "%"
      + "\n" 
      //+ "SAFE EQUITY RISK % :             " + DoubleToStr(SafeEquityRisk, 2) 
      //+ "\n" 
      + ls_2
      + str5 + str3 + str6 
      + "\n"
      + str1
      + "\n" 
      + str2 + str3 + str4 
      + "\n"
//      + "CURRENT PROFIT:                     " + DoubleToStr(CurProfit, 2) 
//      + "\n" 
//      + "POTENTIAL PROFIT:                  " + DoubleToStr(PotProfit, 2) 
//      + "\n"
      + "Pips To TP:                                  " + DoubleToStr(PipToTP, 1) 
      + "\n"      
      + "====================================\n"
      + "Drawdown :                               " + ls_0 + "%"
      + "\n"
      + "Drawdown (Max) :                      " + DoubleToStr(MaxDD,2) + "%"
      + "\n"
      + ls_3
      + "Total Profit/Loss :                        " + DoubleToStr(calculatePLBalance(),2) + "\n"      
      + ls_1
      );
}

double calculatePLBalance() {
   double gd_TotalPL = 0;
   int li_0 = OrdersHistoryTotal();
   for (int li_4 = 0; li_4 < li_0; li_4++) {
      OrderSelect(li_4, SELECT_BY_POS, MODE_HISTORY);
      if (OrderMagicNumber() == MagicNumber) gd_TotalPL += OrderProfit() + OrderSwap() + OrderCommission();
   }
return(gd_TotalPL);   
}

double balanceDeviation() {
   double bd;
   bd = (AccountEquity() / AccountBalance() - 1.0) / (-0.01);
   if (bd <= 0.0) return (0);
   return (bd);
}

int OrdersCountByMagic(int magic) {
   int total = OrdersTotal();
   int count = 0;
   for (int i = 0; i < total; i++) {
      OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderType() == OP_SELL || OrderType() == OP_BUY && OrderSymbol() == Symbol() && OrderMagicNumber() == magic) count++;
   }
   return (count);
}

string ReturnErrorMsg(int errCode) {
   if (errCode == 0) return ("HTTP Error");
   if (errCode == 1) return ("Account does not exist or banned");
   if (errCode == 2) return ("Account Activation Successful");
   if (errCode == 3) return ("Account Authentication Successful");
   if (errCode == 4) return ("Account not Activated!!!");
   if (errCode == 5) return ("Insert a valid CLICKBANK ID.");
   return ("Ok");
}

int func1(int a1, int a2, double a3, double a4, double a5, double a6, double a7, double a8, double a9)
{
   if ( a1 && a7 * a8 * a9 <= a5 - a4 ) return(1);
   if ( a2 && a3 - a6 >= a9 * a8 * a7 ) return(1);
   return(0);
}