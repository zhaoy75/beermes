create a recipe edit page, related tables are below 1. The requirement are as below:
1. steps in process should be trade as a section
2. field of each step should be dynamically generated based on step_key information
3. list in each step should be freely editable, addable and deletable
4. qc field is optional, if exist, should be editable, addable and deletable

1. recipt related table


create an recipt list page, 

ビール設計（Recipe）
　IN: 過去のビール設計書をコピー
　Process　
　　-AVB,IBU,SRM,OG,FGの設定
　　-原材料の設定
  　-各工程の設定
　　計算式あり。
　Out：
　　ビール設計書　
原材料仮見積
　IN: ビール設計書＋エキス実績
　Process：
　　-原材料の種類と量を特定
　　-エキス実績に基づく原材料のコスト計算
　　-必要な原材料のリストを作成
　Out: 仕込原材料
在庫確認
　IN: 仕込原材料
　Process：
　　-在庫の有無を確認
　Out: 確定仕込原材料
発注
  IN: 確定仕込原材料
  Process：
    -発注書の作成
    -発注の実行
  Out: 発注書
LOT管理
　STEPs
　　原材料リスト
　　生産物リスト
　　　廃棄、移動
　　加工装置
　　作業指示書
　　加工予定時間
　　QCデータ