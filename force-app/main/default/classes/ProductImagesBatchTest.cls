@isTest
private class ProductImagesBatchTest{

    @TestSetup
    static void makeData(){
        
        Product2 prod1 = new Product2();
        prod1.Name = 'prod1';
        prod1.IsActive = true;
        prod1.SKU__c = 'prod1';
        prod1.Stock__c = 10;
        prod1.Image__c = 'https://cdn.dummyjson.com/products/images/beauty/Eyeshadow%20Palette%20with%20Mirror/thumbnail.png';
        
        insert prod1;

    }

    private class ImageMock implements HttpCalloutMock{

        public HTTPResponse respond(HTTPRequest req){

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'image/png');
            res.setBodyAsBlob(Blob.valueOf('imageBlob'));
            res.setStatusCode(200);

            return res;

        }
    }

    @isTest
    static void myUnitTest(){

        Test.setMock(HttpCalloutMock.class, new ImageMock());
        
        ProductImagesBatch batch = new ProductImagesBatch();

        Test.startTest();
            Database.executeBatch(batch, 1);
        Test.stopTest();

        List<ContentVersion> cvs = new List<ContentVersion>();
        cvs = [SELECT Id FROM ContentVersion];

        System.Assert.areEqual(1, cvs.size());

    }
}