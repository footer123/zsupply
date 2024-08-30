import credits.aleo;
program zksupplierversion01.aleo;


struct Company:
    name as field;
    manager as address;
    finance_department as address;

struct Supplier:
    manager as address;
    name as field;
    level as u8;
    comment as field;

struct QCTeam:
    manager as address;
    name as field;
    level as u8;
    comment as field;

struct Product:
    product_id as field;
    name as field;
    comment as field;
    price as u64;
    supplier_address as address;

struct OrderInfo:
    order_id as field;
    product as Product;
    qty as u64;
    status as u8;
    order_timestamp as u32;
    produce_timestamp as u32;
    complete_timestamp as u32;
    total_price as u64;

struct QCInfo:
    order_id as field;
    product_id as field;
    qc_status as u8;
    qc_signature as signature;

record QC_Record:
    owner as address.private;
    supplier as address.private;
    company as address.private;
    qc as address.private;
    order_id as field.private;
    qc_result as QCInfo.private;

record Order_Record:
    owner as address.private;
    supplier as address.private;
    company as address.private;
    qc as address.private;
    order_id as field.private;
    qc_info as QCInfo.private;
    order_info as OrderInfo.private;

record Finance_Record:
    owner as address.private;
    supplier as address.private;
    company as address.private;
    payment_amount as u64.private;
    order_id as field.private;
    sign as signature.private;


mapping companys:
	key as address.public;
	value as Company.public;


mapping suppliers:
	key as address.public;
	value as Supplier.public;


mapping QCs:
	key as address.public;
	value as QCTeam.public;


mapping products:
	key as field.public;
	value as Product.public;


function create_demo_accounts:
    input r0 as Company.private;
    input r1 as Supplier.private;
    input r2 as QCTeam.private;
    async create_demo_accounts r0 r1 r2 into r3;
    output r3 as zksupplierversion01.aleo/create_demo_accounts.future;

finalize create_demo_accounts:
    input r0 as Company.public;
    input r1 as Supplier.public;
    input r2 as QCTeam.public;
    set r0 into companys[r0.manager];
    set r1 into suppliers[r0.manager];
    set r2 into QCs[r0.manager];




function create_product:
    input r0 as Product.private;
    input r1 as Supplier.private;
    assert.eq r0.supplier_address r1.manager;
    assert.eq self.caller r1.manager;
    async create_product r0 into r2;
    output r2 as zksupplierversion01.aleo/create_product.future;

finalize create_product:
    input r0 as Product.public;
    contains suppliers[r0.supplier_address] into r1;
    assert.eq r1 true;
    contains products[r0.product_id] into r2;
    not r2 into r3;
    assert.eq r3 true;
    set r0 into products[r0.product_id];




function update_product:
    input r0 as Product.private;
    assert.eq self.caller r0.supplier_address;
    async update_product r0 into r1;
    output r1 as zksupplierversion01.aleo/update_product.future;

finalize update_product:
    input r0 as Product.public;
    contains products[r0.product_id] into r1;
    assert.eq r1 true;
    set r0 into products[r0.product_id];




function order_products:
    input r0 as Product.private;
    input r1 as u64.private;
    input r2 as u32.private;
    input r3 as address.private;
    input r4 as signature.private;
    mul r0.price r1 into r5;
    hash.bhp256 r2 into r6 as field;
    cast r6 r0 r1 0u8 r2 0u32 0u32 r5 into r7 as OrderInfo;
    cast r6 r0.product_id 0u8 r4 into r8 as QCInfo;
    cast self.caller r0.supplier_address self.caller r3 r6 r8 r7 into r9 as Order_Record.record;
    cast r0.supplier_address r0.supplier_address self.caller r3 r6 r8 r7 into r10 as Order_Record.record;
    async order_products r0 self.caller r3 into r11;
    output r9 as Order_Record.record;
    output r10 as Order_Record.record;
    output r11 as zksupplierversion01.aleo/order_products.future;

finalize order_products:
    input r0 as Product.public;
    input r1 as address.public;
    input r2 as address.public;
    contains QCs[r2] into r3;
    assert.eq r3 true;
    contains products[r0.product_id] into r4;
    assert.eq r4 true;
    contains companys[r1] into r5;
    assert.eq r5 true;



function produce_order_products:
    input r0 as Order_Record.record;
    input r1 as u32.private;
    cast r0.order_info.order_id r0.order_info.product r0.order_info.qty 1u8 r0.order_info.order_timestamp r1 0u32 r0.order_info.total_price into r2 as OrderInfo;
    cast r0.company r0.supplier r0.company r0.qc r0.order_id r0.qc_info r0.order_info into r3 as Order_Record.record;
    cast r0.qc r0.supplier r0.company r0.qc r0.order_info.order_id r0.qc_info into r4 as QC_Record.record;
    output r3 as Order_Record.record;
    output r4 as QC_Record.record;



function update_qc_info:
    input r0 as QC_Record.record;
    input r1 as u8.private;
    input r2 as signature.private;
    cast r0.order_id r0.qc_result.product_id r1 r2 into r3 as QCInfo;
    cast r0.company r0.supplier r0.company r0.qc r0.order_id r3 into r4 as QC_Record.record;
    cast r0.supplier r0.supplier r0.company r0.qc r0.order_id r3 into r5 as QC_Record.record;
    cast r0.qc r0.supplier r0.company r0.qc r0.order_id r3 into r6 as QC_Record.record;
    async update_qc_info r1 into r7;
    output r4 as QC_Record.record;
    output r5 as QC_Record.record;
    output r6 as QC_Record.record;
    output r7 as zksupplierversion01.aleo/update_qc_info.future;

finalize update_qc_info:
    input r0 as u8.public;
    gt r0 0u8 into r1;
    assert.eq r1 true;



function request_retest_quality:
    input r0 as QC_Record.record;
    cast r0.order_id r0.qc_result.product_id 0u8 r0.qc_result.qc_signature into r1 as QCInfo;
    cast r0.supplier r0.supplier r0.company r0.qc r0.order_id r1 into r2 as QC_Record.record;
    output r2 as QC_Record.record;



function notify_pay_the_supplier:
    input r0 as Order_Record.record;
    input r1 as u32.private;
    input r2 as address.private;
    input r3 as signature.private;
    cast r0.order_info.order_id r0.order_info.product r0.order_info.qty 3u8 r0.order_info.order_timestamp r0.order_info.produce_timestamp r1 r0.order_info.total_price into r4 as OrderInfo;
    cast r0.owner r0.supplier r0.company r0.qc r0.order_id r0.qc_info r0.order_info into r5 as Order_Record.record;
    cast r2 r0.supplier r0.company r0.order_info.total_price r0.order_id r3 into r6 as Finance_Record.record;
    async notify_pay_the_supplier self.caller r2 into r7;
    output r6 as Finance_Record.record;
    output r5 as Order_Record.record;
    output r7 as zksupplierversion01.aleo/notify_pay_the_supplier.future;

finalize notify_pay_the_supplier:
    input r0 as address.public;
    input r1 as address.public;
    get companys[r0] into r2;
    assert.eq r2.finance_department r1;



function pay_in_aleo_credits:
    input r0 as Finance_Record.record;
    input r1 as credits.aleo/credits.record;
    cast r0.supplier r0.supplier r0.company r0.payment_amount r0.order_id r0.sign into r2 as Finance_Record.record;
    call credits.aleo/transfer_private r1 r0.supplier r0.payment_amount into r3 r4;
    output r3 as credits.aleo/credits.record;
    output r4 as credits.aleo/credits.record;
    output r2 as Finance_Record.record;


function complete_order:
    input r0 as Order_Record.record;
    assert.eq self.caller r0.owner;
    cast r0.order_info.order_id r0.order_info.product r0.order_info.qty 4u8 r0.order_info.order_timestamp r0.order_info.produce_timestamp r0.order_info.complete_timestamp r0.order_info.total_price into r1 as OrderInfo;
    cast r0.owner r0.supplier r0.company r0.qc r0.order_id r0.qc_info r0.order_info into r2 as Order_Record.record;
    output r2 as Order_Record.record;
