// The 'hello1' program.
import credits.aleo;
program zksupplierversion01.aleo {

    mapping companys: address => Company;
    mapping suppliers: address => Supplier;
    mapping QCs: address => QCTeam;
    mapping products: field => Product;
    
    //const DEFAULT_SIGNATURE : signature = sign1pzaf7r8ham2htl3arzrfd4pqsrqcr3ag20ap6w3ju056drcalvq452zcmjytwvh5vrgx2lfrsvdfmhw0rasz77dqvr8qupfgy9p47pyr22qjwn4zc0pzv87twjygsz9m7ekljmuw4jpzf68rwuq99r0tp735vs6220q7tp60nr7llkwstcvu49wdhydx5x2s3sftjskzawhqve7z6gq;
    
    struct Company {
        name:field,
        manager:address,
        finance_department:address,
    }

    struct Supplier {
        manager:address,
        name:field,
        level:u8,
        comment:field,
    }

    struct QCTeam {
        manager:address,
        name:field,
        level:u8,
        comment:field,
    }


    struct Product {
        product_id:field,
        name: field,
        comment:field,
        price: u64,
        supplier_address:address,
    }


    struct OrderInfo {
        order_id: field,
        product : Product,
        qty: u64,
        status: u8,
        order_timestamp: u32,
        produce_timestamp: u32,
        complete_timestamp: u32,
        total_price: u64,
    }   

    struct QCInfo {
        order_id: field,
        product_id: field,
        qc_status: u8,
        qc_signature: signature,
    }
    record QC_Record {
        owner: address,
        supplier: address,
        company: address,
        qc:address,
        order_id: field,
        qc_result: QCInfo,
    }



    record Order_Record {
        owner: address,
        supplier: address,
        company: address,
        qc: address,
        order_id: field,
        qc_info:QCInfo,
        order_info:OrderInfo,
    }

    record Finance_Record {
        owner: address,
        supplier: address,
        company: address,
        payment_amount: u64,
        order_id:field,
        sign:signature,
    }



    //----------------------------------------------------------------
    // create the demo accounts
    async transition create_demo_accounts(company:Company,supplier:Supplier,qc:QCTeam)->Future {
        // assert_neq(company.manager, supplier.manager);
        // assert_neq(company.manager, company.finance_department);
        // assert_neq(company.manager, qc.manager);
        // assert_neq(supplier.manager, qc.manager);

        return (update_demo_accounts(company,supplier,qc));
    }
   
    async function update_demo_accounts (company:Company,supplier:Supplier,qc:QCTeam)  {
        companys.set(company.manager,company);
        suppliers.set(company.manager,supplier);
        QCs.set(company.manager,qc);
    }


    //----------------------------------------------------------------
    //create product
    async transition create_product(product:Product,supplier:Supplier)->Future {
        assert_eq(product.supplier_address,supplier.manager);
        assert_eq(self.caller, supplier.manager);


        return (finalize_create_product(product));
    }
    //----------------------------------------------------------------
    // insert the product
    async function finalize_create_product(product:Product){
        let contain_supplier : bool = suppliers.contains(product.supplier_address);
        assert(contain_supplier);

        let contain_product_id : bool = products.contains(product.product_id);
        assert(!contain_product_id);

        products.set(product.product_id,product);

    }
    
    //----------------------------------------------------------------
    // update the product
    async  transition update_product(product:Product)->Future {
        assert_eq(self.caller, product.supplier_address);

        return (finalize_update_product(product));
    }

    async function finalize_update_product(product:Product){
        let is_contain : bool = products.contains(product.product_id);
        assert(is_contain);

        products.set(product.product_id,product);
    }



    //----------------------------------------------------------------
    // order the products
    async transition order_products(
        product:Product,
    qty:u64,timestamp:u32,qc:address,
    default_signature:signature)->(Order_Record,Order_Record,Future){

        let total_price : u64 = product.price * qty;
        let order_id : field = BHP256::hash_to_field(timestamp);
        let order_info : OrderInfo = OrderInfo{
            order_id: order_id,
            product : product,
            status: 0u8,
            order_timestamp: timestamp,
            produce_timestamp: 0u32,
            complete_timestamp: 0u32,
            qty: qty,
            total_price: total_price,
        };

        let qc_info : QCInfo = QCInfo{
            order_id: order_id,
            product_id: product.product_id,
            qc_status: 0u8,
            qc_signature: default_signature,
        };

        let order_record : Order_Record  = Order_Record {
            owner: self.caller,
            supplier: product.supplier_address,
            company: self.caller,
            order_id:order_id,
            qc: qc,
            qc_info:qc_info,
            order_info:order_info,
        };

        let order_record_for_supplier : Order_Record  = Order_Record {
            owner: product.supplier_address,
            supplier: product.supplier_address,
            company: self.caller,
            order_id:order_id,
            qc: qc,
            qc_info:qc_info,
            order_info:order_info,
        };

        return (order_record,order_record_for_supplier,finalize_order_products(product, self.caller,qc)); 
    }

    async function finalize_order_products(product:Product,order_address:address,qc:address) {

        assert(QCs.contains(qc));
        assert(products.contains(product.product_id));
        assert(companys.contains(order_address));

    }


    //----------------------------------------------------------------
    // produce_order_products  asks for the qc 

    transition produce_order_products(order:Order_Record,timestamp:u32)-> (Order_Record,QC_Record){

        // update order status
        let order_info : OrderInfo = order.order_info;
        let new_order_info : OrderInfo = OrderInfo{
            order_id: order_info.order_id,
            product : order_info.product,
            qty: order_info.qty,
            status: 1u8,
            order_timestamp: order_info.order_timestamp,
            produce_timestamp: timestamp,
            complete_timestamp: 0u32,
            total_price: order_info.total_price,
        };

        let new_order_record : Order_Record = Order_Record{
            owner: order.company,
            supplier: order.supplier,
            company: order.company,
            qc: order.qc,
            order_id: order.order_id,
            qc_info:order.qc_info,
            order_info:order.order_info,
        };

        ////////////////////////////////
        // ask for qc 
        let qc_record : QC_Record = QC_Record{
            owner: order.qc,
            supplier: order.supplier,
            company: order.company,
            qc:order.qc,
            order_id: order_info.order_id,
            qc_result: order.qc_info,
        };

      
        return (new_order_record,qc_record);

    }


    //----------------------------------------------------------------
    // update the qc info
    async transition update_qc_info (qc_record:QC_Record,qc_status:u8,qc_sign:signature) -> (QC_Record,QC_Record,QC_Record,Future) {

        let qc_info : QCInfo = QCInfo{
            order_id: qc_record.order_id,
            product_id: qc_record.qc_result.product_id,
            qc_status: qc_status,
            qc_signature: qc_sign,
        };
        
        let qc_record_for_company : QC_Record = QC_Record{
            owner: qc_record.company,
            supplier: qc_record.supplier,
            company: qc_record.company,
            qc:qc_record.qc,
            order_id: qc_record.order_id,
            qc_result: qc_info,
        };

        let qc_record_for_supplier : QC_Record = QC_Record{
            owner: qc_record.supplier,
            supplier: qc_record.supplier,
            company: qc_record.company,
            qc:qc_record.qc,
            order_id: qc_record.order_id,
            qc_result: qc_info,
        };

        let qc_record_for_qc : QC_Record = QC_Record{
            owner: qc_record.qc,
            supplier: qc_record.supplier,
            company: qc_record.company,
            qc:qc_record.qc,
            order_id: qc_record.order_id,
            qc_result: qc_info,
        };

        return (qc_record_for_company,qc_record_for_supplier,qc_record_for_qc,finalize_update_qc_info(qc_status));
    }

    async function finalize_update_qc_info  (qc_status:u8) {
        assert(qc_status > 0u8);
    }


    //--------------------------
    // qc not passed, re-test the quality

    transition request_retest_quality (qc_record:QC_Record) -> QC_Record {
        let reset_qc : QCInfo = QCInfo{
            order_id: qc_record.order_id,
            product_id: qc_record.qc_result.product_id,
            qc_status: 0u8,
            qc_signature: qc_record.qc_result.qc_signature,
        };

        let new_qc_record : QC_Record = QC_Record{
            owner: qc_record.supplier,
            supplier: qc_record.supplier,
            company: qc_record.company,
            qc:qc_record.qc,
            order_id: qc_record.order_id,
            qc_result: reset_qc,
        };

        return (new_qc_record);
    }


    //----------------------------------------------------------------
    // After the quality inspection is passed, notify the finance department to pay the supplier
    async transition notify_pay_the_supplier (order_record:Order_Record,timestamp:u32,finance_department:address,sign:signature)->(Finance_Record,Order_Record,Future){
        
        let order_info : OrderInfo = order_record.order_info;
        let new_order_info : OrderInfo = OrderInfo{
            order_id: order_info.order_id,
            product : order_info.product,
            qty: order_info.qty,
            status: 3u8,
            order_timestamp: order_info.order_timestamp,
            produce_timestamp: order_info.produce_timestamp,
            complete_timestamp: timestamp,
            total_price: order_info.total_price,

        };
        let order_record_for_manager : Order_Record =  Order_Record {
            owner: order_record.owner,
            supplier: order_record.supplier,
            company: order_record.company,
            qc: order_record.qc,
            order_id: order_record.order_id,
            qc_info:order_record.qc_info,
            order_info:order_record.order_info,
        };

        let pay_record : Finance_Record = Finance_Record {
            owner: finance_department,
            supplier: order_record.supplier,
            company: order_record.company,
            payment_amount: order_record.order_info.total_price,
            order_id:order_record.order_id,
            sign:sign,
        };

        return (pay_record,order_record_for_manager,finalize_notify_pay_the_supplier(self.caller, finance_department));
    }

    async function finalize_notify_pay_the_supplier(manager:address,finance_department:address){
        let company : Company = companys.get(manager);
        assert_eq(company.finance_department, finance_department);
    
    }

    //----------------------------------------------------------------
    // payment

    transition pay_in_aleo_credits (finance:Finance_Record,payment:credits.aleo/credits) ->  (credits.aleo/credits,credits.aleo/credits,Finance_Record){
        
        let finance_supplier : Finance_Record = Finance_Record {
            owner: finance.supplier,
            supplier: finance.supplier,
            company: finance.company,
            payment_amount: finance.payment_amount,
            order_id:finance.order_id,
            sign:finance.sign,
        };
        let (out_supplier,out_finace): (credits.aleo/credits, credits.aleo/credits) 
            = credits.aleo/transfer_private(
                payment,
                finance.supplier,
                finance.payment_amount,
            );
        return (out_supplier,out_finace,finance_supplier);
    }


    //----------------------------------------------
    // finish the order by supplier

    transition complete_order (order_record:Order_Record) -> Order_Record {

        assert_eq(self.caller, order_record.owner);

        let order_info : OrderInfo = order_record.order_info;
        let new_order_info : OrderInfo = OrderInfo{
            order_id: order_info.order_id,
            product : order_info.product,
            qty: order_info.qty,
            status: 4u8,
            order_timestamp: order_info.order_timestamp,
            produce_timestamp: order_info.produce_timestamp,
            complete_timestamp: order_info.complete_timestamp,
            total_price: order_info.total_price,
        };

        let order_record_for_supplier : Order_Record =  Order_Record {
            owner: order_record.owner,
            supplier: order_record.supplier,
            company: order_record.company,
            qc: order_record.qc,
            order_id: order_record.order_id,
            qc_info:order_record.qc_info,
            order_info:order_record.order_info,
        };

        return (order_record_for_supplier);

    }

}
