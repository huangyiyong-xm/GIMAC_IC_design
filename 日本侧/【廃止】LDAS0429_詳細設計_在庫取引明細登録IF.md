# 0. 表紙

| モジュール名 | プログラムID | プログラム名 |
| --- | --- | --- |
| IC | LDAS0429 | 在庫取引明細登録IF |


| RFC        | Version | 更新日      | 更新者 | 更新内容 | 確認日 | 確認者 | 承認日     | 承認者 |
| ---------- | :-----: | ----------- | :----: | -------- | ------ | :----: | ---------- | :----: |
| - |  1.0.0  | 2025/10/27 | オヘダイチロー | 初版作成   | 2025/XX/XX  |  XXX  | 2025/XX/XX |  XXX  |

## 1. 処理概要

### 1.1. 機能概要

引数より在庫取引明細ファイルを作成する。

### 1.2. 処理概要フロー

### 1.3. プログラム入出力パラメータ

#### 1.3.1. 引数

| No. | パラメータ論理名 | パラメータ物理名 | 属性 | 備考 |
| --- | --- | --- | --- | --- |
| 1 | TP処理番号 | ps_operation_no |  |  |
| 2 | TP処理明細番号 | ps_operation_seq |  |  |
| 3 | TP処理枝番 | ps_operation_brn |  |  |
| 4 | IC工場処理日 | ps_ic_slip_date |  |  |
| 5 | 品目番号 | ps_itemno |  |  |
| 6 | 供給者 | ps_supplier |  |  |
| 7 | 使用者 | ps_usercd |  |  |
| 8 | IC更新日時 | ps_ic_update_datetime |  |  |
| 9 | 内部トランザクションコード | ps_inter_txn |  |  |
| 10 | ソースコード | ps_source |  |  |
| 11 | 処理コード | ps_code |  |  |
| 12 | 入力処理識別 | ps_input_operation_id |  |  |
| 13 | 入力変更区分 | ps_input_control_class |  |  |
| 14 | IA処理済サイン | ps_ips_sign |  |  |
| 15 | 受領データ作成済サイン | ps_receive_datps_sign |  |  |
| 16 | 起票日 | ps_input_date |  |  |
| 17 | 入庫数 | pn_in_qty |  |  |
| 18 | 出庫数 | pn_out_qty |  |  |
| 19 | 手持在庫数 | pn_oh_qty |  |  |
| 20 | 担当課 | ps_org_section_mrp |  |  |
| 21 | 担当者 | ps_org_person_mrp |  |  |
| 22 | 品目タイプ | ps_item_type |  |  |
| 23 | AIRSサイン | ps_airs_sign |  |  |
| 24 | オーダー番号 | ps_order_no |  |  |
| 25 | オーダー／所要数 | ps_order_qty |  |  |
| 26 | 納入日 | ps_due_date |  |  |
| 27 | 親品目番号 | ps_parent_itemno |  |  |
| 28 | 親供給者 | ps_parent_supplier |  |  |
| 29 | 親使用者 | ps_parent_usercd |  |  |
| 30 | 独立需要送り先区分 | ps_ind_user_class |  |  |
| 31 | 独立需要送り先コード | ps_ind_user_code |  |  |
| 32 | 生試初品区分 | ps_pilot_class |  |  |
| 33 | フリーコメント | ps_remark |  |  |
| 34 | 相手先システム識別 | ps_request_system_code |  |  |
| 35 | 費用振替先区分 | ps_transfer_class |  | 1：SUコード、2：原価センター、３：受払種別 |
| 36 | 費用振替先コード | ps_transfer_code |  | 2：原価センターの時、10桁になる |
| 37 | 勘定科目コード | ps_account_heading |  |  |
| 38 | 目的No | ps_budget_no |  |  |
| 39 | 受払種別コード | ps_account_code_sales |  |  |
| 40 | 振替理由コード | ps_transfer_reason_code |  |  |
| 41 | 入力品目番号 | ps_input_itemno |  |  |
| 42 | 入力供給者 | ps_input_supplier |  |  |
| 43 | 入力使用者 | ps_input_usercd |  |  |
| 44 | 入力オーダ番号 | ps_input_order_no |  |  |
| 45 | 入力カード識別 | ps_input_card_id |  |  |
| 46 | 入力ベンダーコード | ps_input_vendor_code |  |  |
| 47 | 入力照合番号 | ps_input_slip_no |  |  |
| 48 | 入力数量 | pn_input_qty |  |  |
| 49 | 入力理由コード | ps_input_reason_code |  |  |
| 50 | 入力責任工程 | ps_input_rp_process |  |  |
| 51 | 入力責任職場／メーカー区分 | ps_input_rp_shop_class |  |  |
| 52 | 入力責任職場／メーカー | ps_input_rp_shop_code |  |  |
| 53 | 入力組立ライン | ps_input_assy_line_code |  |  |
| 54 | 入力組立順序番号 | ps_input_assy_seq |  |  |
| 55 | 入力金額 | pn_input_amount |  |  |
| 56 | 入力移動先使用者 | ps_input_mv_usercd |  |  |
| 57 | 入力費用振替先区分 | ps_input_transfer_class |  |  |
| 58 | 入力費用振替先コード | ps_input_transfer_code |  |  |
| 59 | 入力勘定科目コード | ps_input_account_heading |  |  |
| 60 | 入力目的No | ps_input_budget_no |  |  |
| 61 | 入力受払種別コード | ps_input_account_code_sales |  |  |
| 62 | 入力仕掛サイン | ps_input_in_process_sign |  |  |
| 63 | インボイスNo | ps_invoice_no |  |  |
| 64 | B/LNo | ps_bl_no |  |  |
| 65 | ケースマークオーダ番号 | ps_case_mark_order_no |  |  |
| 66 | ケースNo | ps_case_no |  |  |
| 67 | 登録者ID | ps_register_user_id |  |  |
| 68 | G-SDMオーダー番号 | ps_gsdm_order_no |  |  |
| 69 | 外売品フラグ | ps_ |  |  |
| 70 | HU-ID | ps_handling_unit_id |  |  |
| 71 | 工程番号 | ps_process_number |  |  |
| 72 | 原価用品目番号 | ps_cc_itemno |  |  |
| 73 | 原価用供給者 | ps_cc_supplier |  |  |
| 74 | 原価用使用者 | ps_cc_usercd |  |  |
| 75 | 原価用オーダー番号 | ps_cc_order_no |  |  |

#### 1.3.2. 戻り値

| No. | パラメータ論理名 | パラメータ物理名 | 属性 | 備考 |
| --- | --- | --- | --- | --- |
| 1 | 処理ステータス | rs_sp_status | INTEGER | 0:NormalEnd-1:SQLError |
| 2 | SQLコード | rs_sql_error | VARCHAR |  |
| 3 | エラーコード | rs_err_code | VARCHAR |  |
| 4 | エラーメッセージ | rs_err_msg | VARCHAR |  |
| 5 | エラー位置 | rs_err_focus | VARCHAR |  |

### 1.4. その他制御・要件

| 排他制御 |  |  |
| --- | --- | --- |
| 楽観 | 悲観 | 無し |
| ● | - | - |

| 項目 | 制約・制御・要件など | 記載内容説明 |
| --- | --- | --- |
| パフォーマンス要件 | 特になし。  | 特別なパフォーマンス要件がある場合に要件内容とその対処法を記述。 |

### 1.5. 入出力一覧

| No | 入出力対象 | 名称 | 物理名称 | C | R | U | D | 備考 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | テーブル | 品目共通 | la_itemcomn | - | ○ | - | - |  |
| 2 | テーブル | 在庫取引明細ファイル | ld_trn_trans | ○ | - | - | - |  |



## 2. 詳細処理

### 2.1. 引数の取得とチェック

### 2.2. 初期処理

- システム日時の値セット

```sql
     ld_sysdatetime := statement_timestamp(); 
```

### 2.3. 主処理

```sql
if a_n_itemno = " " then
    select n_itemno
      into l_n_itemno
      from de_itemcomn
     where itemno = a_itemno;

    if l_n_itemno is null then
        let l_n_itemno = " ";
    end if
else
    let l_n_itemno = a_n_itemno;
end if

-- GET P_N_ITEMNO
if a_p_itemno <> " " then
    select n_itemno
      into l_p_n_itemno
      from de_itemcomn
     where itemno = a_p_itemno;
end if

if l_p_n_itemno is null then
    let l_p_n_itemno = " ";
end if
```

```sql
 INSERT
      INTO ld_trn_trans
           (operation_no,   --TP処理番号
            operation_seq,   --TP処理明細番号
            operation_brn,   --TP処理枝番  
            ic_slip_date,   --IC工場処理日  
            itemno,   --品目番号  
            supplier,   --供給者  
            usercd,   --使用者  
            ic_update_datetime,   --IC更新日時
            inter_txn,   --内部トランザクションコード  
            source,   --ソースコード  
            code,   --処理コード  
            input_operation_id,   --入力処理識別  
            input_control_class,   --入力変更区分  
            ia_sign,   --IA処理済みサイン  
            receive_data_sign,   --受領データ作成済サイン  
            input_date,   --起票日  
            in_qty,   --入庫数  
            out_qty,   --出庫数  
            oh_qty,   --手持在庫数  
            org_section_mrp,   --担当課  
            org_person_mrp,   --担当者  
            item_type,   --品目タイプ  
            airs_sign,   --AIRSサイン  
            order_no,   --オーダー番号  
            order_qty,   --オーダー/所要数  
            due_date,   --納入日  
            parent_itemno,   --親品目番号  
            parent_supplier,   --親供給者  
            parent_usercd,   --親使用者  
            ind_user_class,   --独立需要送り先区分  
            ind_user_code,   --独立需要送り先コード  
            pilot_class,   --生試初品区分  
            remark,   --フリーコメント  
            request_system_code,   --相手先システム識別  
            transfer_class,   --費用振替先区分  
            transfer_code,   --費用振替先コード  
            account_heading,   --勘定科目コード  
            budget_no,   --目的No  
            account_code_sales,   --受払種別コード  
            transfer_reason_code,   --振替理由コード  
            input_itemno,   --入力品目番号  
            input_supplier,   --入力供給者  
            input_usercd,   --入力使用者  
            input_order_no,   --入力オーダ番号  
            input_card_id,   --入力カード識別  
            input_vendor_code,   --入力ベンダーコード  
            input_slip_no,   --入力照合番号  
            input_qty,   --入力数量  
            input_reason_code,   --入力理由コード  
            input_rp_process,   --入力責任工程  
            input_rp_shop_class,   --入力責任職場／メーカー区分  
            input_rp_shop_code,   --入力責任職場／メーカー  
            input_assy_line_code,   --入力組立ライン  
            input_assy_seq,   --入力組立順序番号  
            input_amount,   --入力金額  
            input_mv_usercd,   --入力移動先使用者  
            input_transfer_class,   --入力費用振替先区分  
            input_transfer_code,   --入力費用振替先コード  
            input_account_heading,   --入力勘定科目コード  
            input_budget_no,   --入力目的No  
            input_account_code_sales,   --入力受払種別コード  
            input_in_process_sign,   --入力仕掛サイン  
            invoice_no,   --インボイスNo  
            bl_no,   --B/LNo  
            case_mark_order_no,   --ケースマークオーダ番号  
            case_no,   --ケースNo  
            register_user_id,   --登録者ID  
            gsdm_order_no,   --G-SDMオーダー番号  
            external_sales_flg,   --外売品フラグ  
            handling_unit_id,   --HU-ID 
            strc_lt_proc_no,   --構成LT用工程番号  
            cc_itemno,   --原価用品目番号  
            cc_supplier,   --原価用供給者  
            cc_usercd,   --原価用使用者  
            cc_order_no,   --原価用オーダー番号  
            update_counter,   --更新カウンタ
            create_datetime,   --登録日時  
            create_author,   --登録者
            create_pgmid,   --登録PGID  
            update_datetime,   --更新日時
            update_author,   --更新者  
            update_pgmid)   --更新PGID
    VALUES (pn_operation_no,  
            pn_operation_seq, 
            pn_peration_brn,
            ps_ic_slip_date,  
            ps_itemno,  --品目番号
            ps_supplier, 
            ps_usercd,   
            ld_sysdatetime,
            ps_inter_txn, 
            ps_source,
            ps_code, 
            ps_input_operation_id,  
            ps_input_control_class, 
            ps_ia_sign,  
            ps_receive_data_sign,  
            ps_input_date, 
            pn_in_qty,  
            pn_out_qty, 
            pn_oh_qty, 
            ps_org_section_mrp,   
            ps_org_person_mrp,
            ps_item_type,
            ps_airs_sign,  
            ps_order_no,  
            pn_order_qty,
            ps_due_date,
            ps_parent_itemno, 
            ps_parent_supplier, 
            ps_parent_usercd, 
            ps_ind_user_class, 
            ps_ind_user_code,  
            ps_pilot_class,  
            ps_remark, 
            ps_request_system_code,  
            ps_transfer_class,  
            ps_transfer_code, 
            ps_account_heading, 
            ps_budget_no, 
            ps_account_code_sales,   
            ps_transfer_reason_code,  
            ps_input_itemno,  --入力品目番号
            ps_input_supplier,   
            ps_input_usercd,  
            ps_input_order_no, 
            ps_input_card_id,   
            ps_input_vendor_code,   
            ps_input_slip_no,  
            pn_input_qty,   
            ps_input_reason_code,  
            ps_input_rp_process, 
            ps_input_rp_shop_class, 
            ps_input_rp_shop_code,  
            ps_input_assy_line_code, 
            ps_input_assy_seq,  
            pn_input_amount,  
            ps_input_mv_usercd,   
            ps_input_transfer_class,  
            ps_input_transfer_code,   
            ps_input_account_heading,  
            ps_input_budget_no,  
            ps_input_account_code_sales,  
            ps_input_in_process_sign,  
            ps_invoice_no,  
            ps_bl_no, 
            ps_case_mark_order_no,  
            ps_case_no,  
            ps_register_user_id,   
            ps_gsdm_order_no,   
            ps_external_sales_flg, 
            ps_handling_unit_id, 
            ps_strc_lt_proc_no,  
            ps_cc_itemno, 
            ps_cc_supplier, 
            ps_cc_usercd,  
            ps_cc_order_no,  
            0,
            ld_sysdatetime,  
            ps_register_user_id,
            'LDAS0429', 
            ld_sysdatetime,
            ps_register_user_id,  
            'LDAS0429');
```

### 2.4. 終了処理

- 正常終了処理を行う

| No. | 戻り値           | 属性    | 設定値   |
| --- | ---------------- | ------- | -------- |
| 1   | 処理ステータス   | INTEGER | 0        |
| 2   | SQL コード       | VARCHAR | ' ' (スペース) |
| 3   | エラーコード     | VARCHAR | ' ' (スペース) |
| 4   | エラーメッセージ | VARCHAR | ' ' (スペース) |
| 5   | エラー位置       | VARCHAR | ' ' (スペース) |

## 3. 補足説明

### 3.1. 戻り値について

- ステータスについて
  - 0 : Normal End
  - -1 : Abnormal End
  - -2 : PGM エラー

### 3.2. エラー発生時の対応について

- RAISE EXCEPTIONのエラーが発生した場合、処理終了
  
- SQL エラーが発生した場合、エラーログを出力して処理終了
  
  | No. | 戻り値           | 属性    | 設定値   |
  | --- | ---------------- | ------- | -------- |
  | 1   | 処理ステータス   | INTEGER | -1       |
  | 2   | SQL コード       | VARCHAR | SQLSTATE |
  | 3   | エラーコード     | VARCHAR | ' ' (スペース) |
  | 4   | エラーメッセージ | VARCHAR | SQLERRM  |
  | 5   | エラー位置       | VARCHAR | LDAS0429 |