@isTest
global class MeterReaderHttpCalloutMock  implements HttpCalloutMock{

    //Implement the interface method
    global HTTPResponse respond (HttpRequest request)
    {
        HttpResponse response = new HttpResponse();
        //Here we defind in the header the type of data this HttpResponse will contain in the body
        response.setHeader('Content-Type', 'application/json');
        response.setBody(HelperMeterReaderTest.jsonTest);
        if(request.getEndpoint().contains('300'))
        {
            response.setStatusCode(300);
        }
        else 
        {
            response.setStatusCode(200);
        }

        return response;
    }
}