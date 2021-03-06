//+------------------------------------------------------------------+
//|                                                      SMA EMA.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int Ticket=0;//チケット番号が代入される変数
double Pips=0;//Adjust関数の返り値が格納される
datetime time=Time[0];//新たなティックの感知に使う

input double Lots1=0.1;//注文1 Lots
//input double Lots2=0.1;//注文2 Lots　SMAEMA正クロスで発注
//input double Lots3=0.1;//注文3 Lots　5pips以下で両方向発注
//input double Lots4=0.1;//注文4 Lots　720と120SMAクロスで発注
//input double Lots5=0.1;//注文5 Lots
//input double Lots6=0.1;//注文6 Lots
input int slippage=5;//発注可能スリッページ（ポイント）
input int MaxSpread=5;//スプレッド制限（ポイント）

input int SMA_EMAperiod=120;
// input int BBperiod =60;
// input int BBAvePeriod=9;
//input int iiii=60;//SMAEMAクロスをもう一本使う作戦
input int ffff=1000;//720SMAの期間

input int TP1=1500;//注文1利確（ポイント）
input int SL1=1000;//注文1損切（ポイント）
// input int TP2=1000;//注文2利確（ポイント）
// input int SL2=500;//注文2損切（ポイント）
// input int TP3=200;//注文3利確（ポイント）
// input int SL3=200;//注文3損切（ポイント）
// input int TP4=1000;//注文4利確（ポイント）
// input int SL4=500;//注文4損切（ポイント）
input int pos=10;//保有可能ポジション数
input int Interval=15;//エントリー制限間隔（分）

int magic1=11111;//Magic注文1　
// int magic2=22222;//Magic注文2　SMAEMA正クロスで発注
// int magic3=33333;//Magic注文3　5pips以下で両方向発注
// int magic4=44444;//Magic注文4　720と120SMAクロスで発注
//int magic5=55555;//
//int magic6=66666;

input bool Order1=true;//注文1 trueで発注
// input bool Order2=true;//注文2 trueで発注
// input bool Order3=true;//注文3 trueで発注
// input bool Order4=true;//注文4 trueで発注

input bool EarlyClose01=true;//trueで反転サインによる早逃げon
//input bool EarlyClose02=true;//trueで反転サインによるmagic2の早逃げon

input bool TrailingStop1=true;//trueで注文1のトレーリングストップon
input int Trailing_Stop1=10;//注文1のTS追従幅(Pips)
// input bool TrailingStop2=true;//trueで注文2のトレーリングストップon
// input int Trailing_Stop2=30;//注文2のTS追従幅(Pips)
// input bool TrailingStop3=true;//trueで注文3のトレーリングストップon
// input int Trailing_Stop3=20;//注文3のTS追従幅(Pips)
// input bool TrailingStop4=true;//trueで注文4のトレーリングストップon
// input int Trailing_Stop4=30;//注文4のTS追従幅(Pips)

// input bool TrailingTake=false;//trueでトレーリングテイクon
// input int Trailing_Take1=60;//TTの追従幅(Pips)疑似BEより大きくすること

input bool BE1=false;//trueで注文1のブレークイーブンon
input int BErim1=10;//BEされる位置
input int BEPoint1=1;//BEでSLがおかれる位置(BErim以下に設定)
//---------------------------------------------------
input int stocBUY=60;//下抜けで買い
input int stocSELL=40;//上抜けで売り

double X;//前回ティック更新時の値を保存しておく変数 1更新前の情報が必要なスキャルピングに用いる

//double BBArray[BBperiod];
//double BBdiff=0;
//---------------------------------------------------------------------
//関数の定義
double AdjustPoint(string Currency)
  {
   double Calculated_Point=0;//ポイントの単位調整を行った結果を格納するための変数

   int Symbol_Digits=(int)MarketInfo(Currency,MODE_DIGITS);//通貨ペアの小数点以下の桁数を、変数Symbol_Digitsに代入 (int)はキャスト演算子、double型をint型に変換している

   if(Symbol_Digits==2 || Symbol_Digits==3)//例）ドル円　0.001が最小
     {
      Calculated_Point=0.01;
     }
   else
      if(Symbol_Digits==4 || Symbol_Digits==5)//例)ユーロドル　0.00001が最小
        {
         Calculated_Point=0.0001;
        }

   return(Calculated_Point);//AdjustPointにCalculated_Pointの値を返している
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Pips=AdjustPoint(Symbol());//AdjustにはCalculateの値が入っているので、上の関数の定義で決まった0.01か0.0001が代入される
   /*
      for(int i = 1 ; i<=BBperiod ; i++)
        {
         BBArray[i] = iBands(NULL,0,BBperiod,2,0,0,1,i) - iBands(NULL,0,BBperiod,2,0,0,2,i);
        }
   */
   return(0);

  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+--------------------------------------------------------------------------------------------------------------------------------------------------------------
//| Expert tick function
//+--------------------------------------------------------------------------------------------------------------------------------------------------------------
void OnTick()
  {
   int OT=OrdersTotal();//オーダートータル　何度も使うのでここで宣言

//+------------------------------------------------------------------+
//|新たなティックを感知（EAが挿入されたチャートのタイムフレーム）
//+------------------------------------------------------------------+

   bool NewTick=false;

   if(Time[0]!=time)
     {
      NewTick=true;
      time=Time[0];
     }
   else
     {
      NewTick=false;
     }
   /*
   //+------------------------------------------------------------------+
   //| ブレークイーブン　　　　　　　　　　                                         |--------------------------------------------------------------------------------
   //+------------------------------------------------------------------+
   //注文1ブレークイーブン
      if(BE1==true)
        {
         for(int i=OT-1;i>=0;i--)
           {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==magic1)
              {

               //買いポジションの場合
               if(OrderType()==OP_BUY)
                 {
                  double a=OrderOpenPrice()+BEPoint1*Pips;
                  a=NormalizeDouble(a,(int)MarketInfo(Symbol(),MODE_DIGITS));//ブレイクイーブン値の桁を揃える
                  if(OrderSymbol()==Symbol() && Bid>=OrderOpenPrice()+BErim1*Pips && OrderStopLoss()!=a)//もし現在価格が規定値より大きく、かつまだ一度もBEされていなければ
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),a,OrderTakeProfit(),0);//aを新たなストップロスに設定
                    }
                 }

               //売りポジションの場合
               else if(OrderType()==OP_SELL)
                 {
                  double a=OrderOpenPrice()-BEPoint1*Pips;
                  a=NormalizeDouble(a,(int)MarketInfo(Symbol(),MODE_DIGITS));//ブレイクイーブン値の桁を揃える
                  if(OrderSymbol()==Symbol() && Ask<=OrderOpenPrice()-BErim1*Pips && OrderStopLoss()!=a)//もし現在価格が規定値より大きく、かつまだ一度もBEされていなければ
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),a,OrderTakeProfit(),0);//aを新たなストップロスに設定
                    }
                 }

              }
           }
        }
   */
//30の含み損でTPを1に移動(変数を上のBEそのまま使っているので後で変更)
   if(BE1==true)
     {
      for(int i=OT-1; i>=0; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==magic1)
           {

            //買いポジションの場合
            if(OrderType()==OP_BUY)
              {
               double a=OrderOpenPrice()+(BEPoint1*Pips);
               a=NormalizeDouble(a,(int)MarketInfo(Symbol(),MODE_DIGITS));//ブレイクイーブン値の桁を揃える
               if(OrderSymbol()==Symbol() && Bid<=OrderOpenPrice()-BErim1*Pips && OrderTakeProfit()!=a)//もし現在価格が規定値より大きく、かつまだ一度もBEされていなければ
                 {
                  bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),a,0);//aを新たなストップロスに設定
                 }
              }

            //売りポジションの場合
            else
               if(OrderType()==OP_SELL)
                 {
                  double a=OrderOpenPrice()-(BEPoint1*Pips);
                  a=NormalizeDouble(a,(int)MarketInfo(Symbol(),MODE_DIGITS));//ブレイクイーブン値の桁を揃える
                  if(OrderSymbol()==Symbol() && Ask>=OrderOpenPrice()-BErim1*Pips && OrderTakeProfit()!=a)//もし現在価格が規定値より大きく、かつまだ一度もBEされていなければ
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),a,0);//aを新たなストップロスに設定
                    }
                 }

           }
        }
     }

//+------------------------------------------------------------------+
//| トーレーリングストップ・トレーリングテイク                                     |--------------------------------------------------------------------------------
//+------------------------------------------------------------------+

//BE付きトレーリングストップ(注文1)------------------------------------------------------------

   if(TrailingStop1==true)
     {
      for(int i=OT-1; i>=0; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==magic1)
           {

            //買いポジションの場合
            if(OrderType()==OP_BUY && Bid-OrderOpenPrice()>Trailing_Stop1*Pips)
              {
               double Max_Stop_Loss=Bid-Trailing_Stop1*Pips;//現在の買い気配値からトレーリングストップ幅を引いた値をMax_Stop_Lossに代入
               Max_Stop_Loss=NormalizeDouble(Max_Stop_Loss,(int)MarketInfo(Symbol(),MODE_DIGITS));//多分上の計算で取得したmaxStopLossの桁数を揃えている
               double Current_Stop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(Symbol(),MODE_DIGITS));//現在の損切価格を取得して桁数を揃えている

               if(OrderSymbol()==Symbol() && Current_Stop<Max_Stop_Loss)//損切価格の変更
                 {
                  bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),Max_Stop_Loss,OrderTakeProfit(),0);//MaxStopLossを新たなストップロスに設定
                 }
              }

            //売りポジションの場合
            else
               if(OrderType()==OP_SELL && OrderOpenPrice()-Ask>Trailing_Stop1*Pips)
                 {
                  double Max_Stop_Loss=Ask+Trailing_Stop1*Pips;
                  Max_Stop_Loss=NormalizeDouble(Max_Stop_Loss,(int)MarketInfo(Symbol(),MODE_DIGITS));
                  double Current_Stop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(Symbol(),MODE_DIGITS));

                  if(OrderSymbol()==Symbol() && (Current_Stop>Max_Stop_Loss || Current_Stop==0))
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),Max_Stop_Loss,OrderTakeProfit(),0);
                    }
                 }

           }
        }
     }
   /*
   //BE付きトレーリングストップ（注文2）

      if(TrailingStop2==true)
        {
         for(int i=OT-1;i>=0;i--)
           {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==magic2)
              {

               //買いポジションの場合
               if(OrderType()==OP_BUY && Bid-OrderOpenPrice()>30*Pips)
                 {
                  double Max_Stop_Loss=Bid-Trailing_Stop2*Pips;//現在の買い気配値からトレーリングストップ幅を引いた値をMax_Stop_Lossに代入
                  Max_Stop_Loss=NormalizeDouble(Max_Stop_Loss,(int)MarketInfo(Symbol(),MODE_DIGITS));//多分上の計算で取得したmaxStopLossの桁数を揃えている
                  double Current_Stop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(Symbol(),MODE_DIGITS));//現在の損切価格を取得して桁数を揃えている

                  if(OrderSymbol()==Symbol() && Current_Stop<Max_Stop_Loss)//損切価格の変更
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),Max_Stop_Loss,OrderTakeProfit(),0);//MaxStopLossを新たなストップロスに設定
                    }
                 }

               //売りポジションの場合
               else if(OrderType()==OP_SELL && OrderOpenPrice()-Ask>30*Pips)
                 {
                  double Max_Stop_Loss=Ask+Trailing_Stop2*Pips;
                  Max_Stop_Loss=NormalizeDouble(Max_Stop_Loss,(int)MarketInfo(Symbol(),MODE_DIGITS));
                  double Current_Stop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(Symbol(),MODE_DIGITS));

                  if(OrderSymbol()==Symbol() && (Current_Stop>Max_Stop_Loss || Current_Stop==0))
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),Max_Stop_Loss,OrderTakeProfit(),0);
                    }
                 }

              }
           }
        }

   //BE付きトレーリングストップ（注文3）

      if(TrailingStop3==true)
        {
         for(int i=OT-1;i>=0;i--)
           {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==magic3)
              {

               //買いポジションの場合
               if(OrderType()==OP_BUY && Bid-OrderOpenPrice()>10*Pips)//BEの条件
                 {
                  double Max_Stop_Loss=Bid-Trailing_Stop3*Pips;//現在の買い気配値からトレーリングストップ幅を引いた値をMax_Stop_Lossに代入
                  Max_Stop_Loss=NormalizeDouble(Max_Stop_Loss,(int)MarketInfo(Symbol(),MODE_DIGITS));//多分上の計算で取得したmaxStopLossの桁数を揃えている
                  double Current_Stop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(Symbol(),MODE_DIGITS));//現在の損切価格を取得して桁数を揃えている

                  if(OrderMagicNumber()==magic1 && OrderSymbol()==Symbol() && Current_Stop<Max_Stop_Loss)//損切価格の変更
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),Max_Stop_Loss,OrderTakeProfit(),0);//MaxStopLossを新たなストップロスに設定
                    }
                 }

               //売りポジションの場合
               else if(OrderType()==OP_SELL && OrderOpenPrice()-Ask>10*Pips)//BEの条件
                 {
                  double Max_Stop_Loss=Ask+Trailing_Stop3*Pips;
                  Max_Stop_Loss=NormalizeDouble(Max_Stop_Loss,(int)MarketInfo(Symbol(),MODE_DIGITS));
                  double Current_Stop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(Symbol(),MODE_DIGITS));

                  if(OrderMagicNumber()==magic1 && OrderSymbol()==Symbol() && (Current_Stop>Max_Stop_Loss || Current_Stop==0))
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),Max_Stop_Loss,OrderTakeProfit(),0);
                    }
                 }

              }
           }
        }

   //BE付きトレーリングストップ（注文4）

      if(TrailingStop3==true)
        {
         for(int i=OT-1;i>=0;i--)
           {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==magic4)
              {

               //買いポジションの場合
               if(OrderType()==OP_BUY && Bid-OrderOpenPrice()>50*Pips)//BEの条件
                 {
                  double Max_Stop_Loss=Bid-Trailing_Stop4*Pips;//現在の買い気配値からトレーリングストップ幅を引いた値をMax_Stop_Lossに代入
                  Max_Stop_Loss=NormalizeDouble(Max_Stop_Loss,(int)MarketInfo(Symbol(),MODE_DIGITS));//多分上の計算で取得したmaxStopLossの桁数を揃えている
                  double Current_Stop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(Symbol(),MODE_DIGITS));//現在の損切価格を取得して桁数を揃えている

                  if(OrderMagicNumber()==magic1 && OrderSymbol()==Symbol() && Current_Stop<Max_Stop_Loss)//損切価格の変更
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),Max_Stop_Loss,OrderTakeProfit(),0);//MaxStopLossを新たなストップロスに設定
                    }
                 }

               //売りポジションの場合
               else if(OrderType()==OP_SELL && OrderOpenPrice()-Ask>10*Pips)//BEの条件
                 {
                  double Max_Stop_Loss=Ask+Trailing_Stop4*Pips;
                  Max_Stop_Loss=NormalizeDouble(Max_Stop_Loss,(int)MarketInfo(Symbol(),MODE_DIGITS));
                  double Current_Stop=NormalizeDouble(OrderStopLoss(),(int)MarketInfo(Symbol(),MODE_DIGITS));

                  if(OrderMagicNumber()==magic1 && OrderSymbol()==Symbol() && (Current_Stop>Max_Stop_Loss || Current_Stop==0))
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),Max_Stop_Loss,OrderTakeProfit(),0);
                    }
                 }

              }
           }
        }

   //トレーリングテイク------------------------------------------------------------

      if(TrailingTake==false)
        {
         for(int i=OT-1;i>=0;i--)
           {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==magic1)
              {

               //買いポジションの場合
               if(OrderType()==OP_BUY)
                 {
                  double Min_Take_Profit=Bid+Trailing_Take1*Pips;//現在の買い気配値にトレーリングテイク幅を足した値をMax_Take_Profitに代入
                  Min_Take_Profit=NormalizeDouble(Min_Take_Profit,(int)MarketInfo(Symbol(),MODE_DIGITS));//多分上の計算で取得したMaxTakeProfitの桁数を揃えている
                  double Current_Take=NormalizeDouble(OrderTakeProfit(),(int)MarketInfo(Symbol(),MODE_DIGITS));//現在の利確価格を取得して桁数を揃えている

                  if(OrderSymbol()==Symbol() && Current_Take>Min_Take_Profit && Min_Take_Profit>OrderOpenPrice()+1*Pips)//利確価格の変更
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),Min_Take_Profit,0);//MaxTakeProfitを新たなテイクプロフィットに設定
                    }
                 }

               //売りポジションの場合
               else if(OrderType()==OP_SELL)
                 {
                  double Min_Take_Profit=Ask-Trailing_Take1*Pips;
                  Min_Take_Profit=NormalizeDouble(Min_Take_Profit,(int)MarketInfo(Symbol(),MODE_DIGITS));
                  double Current_Take=NormalizeDouble(OrderTakeProfit(),(int)MarketInfo(Symbol(),MODE_DIGITS));

                  if(OrderSymbol()==Symbol() && Current_Take<Min_Take_Profit && Min_Take_Profit<OrderOpenPrice()-1*Pips)//利確価格の変更
                    {
                     bool Modified=OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),Min_Take_Profit,0);//MaxTakeProfitを新たなテイクプロフィットに設定
                    }
                 }

              }
           }
        }
   */


//　　先に宣言　　　　　　　　（この後の分岐で使う最低限）
   double Stoc5=iStochastic(NULL,1,9,3,3,0,0,0,1);//-1メイン
   double Stoc7=iStochastic(NULL,1,9,3,3,0,0,0,2);//-2メイン

   double EMA1=iMA(NULL,5,SMA_EMAperiod,0,MODE_EMA,PRICE_CLOSE,1);
   double SMA1=iMA(NULL,5,SMA_EMAperiod,0,MODE_SMA,PRICE_CLOSE,1);
   double EMA2=iMA(NULL,5,120,0,MODE_EMA,PRICE_CLOSE,2);
   double SMA2=iMA(NULL,5,120,0,MODE_SMA,PRICE_CLOSE,2);
   double MA1=iMA(NULL,5,ffff,0,MODE_SMA,PRICE_CLOSE,1);
   double MA2=iMA(NULL,5,ffff,0,MODE_SMA,PRICE_CLOSE,2);

//+-----------------------------------------------------------------------------------------------------------------------------------------------+
//|                                                                      
//+-----------------------------------------------------------------------------------------------------------------------------------------------+
//ストキャス933のメインラインの40、60クロス　　　　　　SMA　EMAのクロス両方向　　　　　新たなティックが出たタイミング　　　　　SMA　720MAのクロス
   if((Stoc7<stocBUY && Stoc5>stocBUY) || (Stoc7>stocSELL && Stoc5<stocSELL) || (SMA2>EMA2 && SMA1<EMA1) || (SMA2<EMA2 && SMA1>EMA1) || NewTick==true || (SMA2<MA2 && SMA1>MA1) || (SMA2>MA2 && SMA1<MA1))
     {
      //後で宣言
      double Stoc1=iStochastic(NULL,5,54,18,18,0,0,0,1);//メイン
      double Stoc2=iStochastic(NULL,5,54,18,18,0,0,1,1);//シグナル
      double Stoc3=iStochastic(NULL,5,54,18,18,0,0,0,2);//メイン
      double Stoc4=iStochastic(NULL,5,54,18,18,0,0,1,2);//シグナル
      double Stoc6=iStochastic(NULL,5,9,3,3,0,0,1,1);//-1シグナル
      double Stoc8=iStochastic(NULL,5,9,3,3,0,0,1,2);//-2シグナル
      //double SMA2_1=iMA(NULL,5,iiii,0,MODE_SMA,PRICE_CLOSE,1);
      //double EMA2_1=iMA(NULL,5,iiii,0,MODE_EMA,PRICE_CLOSE,1);
      //double SMA20=iMA(NULL,5,120,0,MODE_SMA,PRICE_CLOSE,20);
      //double MA120=iMA(NULL,5,720,0,MODE_SMA,PRICE_CLOSE,120);
      //double Stoc9=iStochastic(NULL,5,60,36,36,0,0,0,0);//H1Stocメイン現在値
      //double Stoc10=iStochastic(NULL,5,60,36,36,0,0,1,0);//H1Stocシグナル現在値
      bool RecentOrder=false;//Interval分以内に注文がなされていた場合trueが返される
      bool RecentEE=false;//Interval分以内にEEがなされていた場合trueが返される
      //double close_0=iClose(NULL,5,0);//現在の終値symbol,timeframe,shift
      double BBAverage=0;

      // BBdiff=iBands(NULL,0,BBperiod,2,0,0,1,0) - iBands(NULL,0,BBperiod,2,0,0,2,0);
      // if(NewTick==true)//NewTickは現在Tick開始時刻と保存された時刻が異なる場合にtrueとなる　そのため、EA稼働時に最初の一回だけtrueになってしまう
      //   {
      //    for(int i = 0 ; i<BBAvePeriod ; i++)
      //      {
      //       BBAverage+=iBands(NULL,0,BBperiod,2,0,0,1,i) - iBands(NULL,0,BBperiod,2,0,0,2,i);
      //      }
      //    BBAverage= BBAverage/BBAvePeriod;
      //   }

      //+------------------------------------------------------------------+
      //| タイムエントリーフィルター（n分前までにエントリーがある場合にはエントリーできない）
      //+------------------------------------------------------------------+
      for(int i=OT-1; i>=0; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)//opened and pending orders
           {
            int TimeDiff=TimeCurrent()-OrderOpenTime();//注文から経過した時間を取得
            TimeDiff=TimeDiff/60;//分に変換
            if(TimeDiff<Interval)
               RecentOrder=true;
           }
        }

      if(OrderSelect(OrdersHistoryTotal()-1,SELECT_BY_POS,MODE_HISTORY)==true)//closed and canceled orders
        {
         int TimeDiff=TimeCurrent()-OrderOpenTime();//注文から経過した時間を取得
         TimeDiff=TimeDiff/60;//分に変換
         if(TimeDiff<Interval)
            RecentOrder=true;
        }

      //+------------------------------------------------------------------+
      //| 反転サインによる早逃げ
      //+------------------------------------------------------------------+
      //特に意味ないけどクローズの戻り値を保存しておく変数
      bool Closed;

      //magic4の注文を720SMAと120SMAのクロスで全決済する
      if(EarlyClose01==true && NewTick==true)
        {
         if((MA2>SMA2 && MA1<SMA1) || (MA2<SMA2 && MA1>SMA1))//720MAと120SMAクロスで全決済
           {
            for(int i=OT-1; i>=0; i--)
              {
               if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==magic4)//magicによる指定なし
                 {
                  Closed=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,clrNONE);
                 }
              }
           }
        }

      //magic2の注文をSMAEMAクロスで全決済する
      if(EarlyClose02==true && NewTick==true)
        {
         if((SMA1>EMA1 && SMA2<EMA2) || (SMA1<EMA1 && SMA2>EMA2))//SMAEMAクロスで全決済
           {
            for(int i=OT-1; i>=0; i--)
              {
               if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderMagicNumber()==magic2)//magic2の注文のみ
                 {
                  Closed=OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),0,clrNONE);
                 }
              }
           }
        }

      //+------------------------------------------------------------------+
      //| スプレッドフィルター、タイムエントリーフィルター、オーダー数制限付き注文
      //+------------------------------------------------------------------+

      //注文1
      if(MarketInfo(Symbol(),MODE_SPREAD)<MaxSpread && pos>OT && RecentOrder!=true && Order1==true)//SF,PF,TEF
        {

         if(/*Stoc9<80 && Stoc9>20 && */MA1<SMA1 && SMA1<EMA1 &&/* Stoc1<Stoc2 &&*/ (Stoc7>stocBUY && Stoc5<stocBUY) /*&& BBdiff>BBAverage  && SMA2_1<EMA2_1&&Stoc1<50*/)//買い条件を追加
           {
            Ticket=OrderSend(NULL,0,Lots1,Ask,slippage,Ask-SL1*_Point,Ask+TP1*Point,"EA名を記述",magic1,0);
           }

         if(/*Stoc9<80 && Stoc9>20 && */MA1>SMA1 && SMA1>EMA1 &&/* Stoc1>Stoc2 &&*/ (Stoc7<stocSELL && Stoc5>stocSELL) /*&& BBdiff>BBAverage  && SMA2_1>EMA2_1&&Stoc1>50*/)//売り条件を追加
           {
            Ticket=OrderSend(NULL,1,Lots1,Bid,slippage,Bid+SL1*_Point,Bid-TP1*Point,"EA名を記述",magic1,0);
           }
        }
      /*
            //注文2（SMAEMAの正方向へのクロスでのエントリーTP/SL:20/20　負の方向へは発注無し SMAEMA逆クロスで決済）

            if(MarketInfo(Symbol(),MODE_SPREAD)<MaxSpread && RecentOrder!=true && Order2==true)//SF,PF,TEF
              {

               if(MA1<SMA1 && (SMA1>EMA1 && SMA2<EMA2))//買い条件を追加
                 {
                  Ticket=OrderSend(NULL,0,Lots2,Ask,slippage,Ask-SL2*_Point,Ask+TP2*Point,"EA名を記述",magic2,0);
                 }

               if(MA1>SMA1 && (SMA1>EMA1 && SMA2<EMA2))//売り条件を追加
                 {
                  Ticket=OrderSend(NULL,1,Lots2,Bid,slippage,Bid+SL2*_Point,Bid-TP2*Point,"EA名を記述",magic2,0);
                 }
              }

            //注文3(720SMAの傾きが120区間で5pips以下＝レンジの時に、SMAEMAのクロスで両方向へ発注　TP/SL:20/20 TS:10)

            if(MarketInfo(Symbol(),MODE_SPREAD)<MaxSpread && RecentOrder!=true && Order3==true)//SF,PF,TEF
              {

               if(MathAbs(MA1-MA120)<=5*Pips && (SMA1<EMA1 && SMA2>EMA2))//買い条件を追加
                 {
                  Ticket=OrderSend(NULL,0,Lots3,Ask,slippage,Ask-SL3*_Point,Ask+TP3*Point,"EA名を記述",magic3,0);
                 }

               if(MathAbs(MA1-MA120)<=5*Pips && (SMA1>EMA1 && SMA2<EMA2))//売り条件を追加
                 {
                  Ticket=OrderSend(NULL,1,Lots3,Bid,slippage,Bid+SL3*_Point,Bid-TP3*Point,"EA名を記述",magic3,0);
                 }
              }

            //注文4(720SMAと120SMAのクロスでSL50/TP100 反対クロスで決済)

            if(MarketInfo(Symbol(),MODE_SPREAD)<MaxSpread && RecentOrder!=true && Order4==true)//SF,PF,TEF
              {

               if(MA1<SMA1 && MA2>SMA2)//買い条件を追加
                 {
                  Ticket=OrderSend(NULL,0,Lots4,Ask,slippage,Ask-SL4*_Point,Ask+TP4*Point,"EA名を記述",magic4,0);
                 }

               if(MA1>SMA1 && MA2<SMA2)//売り条件を追加
                 {
                  Ticket=OrderSend(NULL,1,Lots4,Bid,slippage,Bid+SL4*_Point,Bid-TP4*Point,"EA名を記述",magic4,0);
                 }
              }
            //      X=close_0;//次回ティック更新の時のために保存しておく
      */
     }
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//リカバリーファクタ-プロフィットファクター
   return(TesterStatistics(STAT_PROFIT)/TesterStatistics(STAT_BALANCE_DD)-TesterStatistics(STAT_PROFIT_FACTOR));
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
