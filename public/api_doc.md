
Company REST/JSON API
===========

This simple web service allows the client to create, view, edit and delete companies, that each have a set of parameters and a list of owners. Each owner can have a passport as a PDF file, which can be uploaded using the API.

Reading
----------

The API tries to adhere to the REST convention. Each of the two resources, `companies` and `owners`, are created, read, updated and deleted by the HTTP methods `POST`, `GET`, `PUT` and `DELETE`. The API always returns JSON data and expects JSON data as the request body for the `POST` and `PUT` methods. In the following, we use `curl` to demonstrate the functionality of the api.

To get a list of companies

    $ curl -i http://localhost/companies

which returns

    HTTP/1.1 200 OK
    ... (headers)
    
    {
    "companies": [
        {
            "id":       Company id,
            "name":     "Example company",
            "address":  "Sample Street, 1",
            "city":     "Aarhus",
            "country:   "Denmark",
            "email":    "company@example.com",
            "phone":    "+4512345678",
            "owners":   [1, 3, 5]
        },
        ... (more companies)
        ]
    }

The attributes are self-explanatory, except `"owners"` which contains a list of owner `id`'s, that is, keys for the table of owners.

A specific company is requested by its `id`, for example

    $ curl -i http://localhost/companies/1
    
yields

    {
        "company": {
            "id":       1,
            "name":     "Example company",
            "address":  "Sample Street, 1",
            "city":     "Aarhus",
            "country:   "Denmark",
            "email":    "company@example.com",
            "phone":    "+4512345678",
            "owners":   [1, 3]
        }
        "owners": [
            {
                "id":           1,
                "name":         "Owner 1"
                "company_id":   1
                "passport":     "http://localhost/owners/1/passport.pdf"
            },
            {
                "id":           3,
                "name":         "Owner 2",
                "company_id":   1,
                "passport":     "http://localhost/owners/2/passport.pdf"
            }
        ]
    }
    
When requesting a single company, we sideload its particular owners in order to lower the number of requests the client has to send. However, we can also access the owners individually using the `/owners` endpoint

    $ curl -i http://localhost/owners/1
    
Returns the owner with `id`=1:

    {
        "owner": {
            "id":           1,
            "name":         "Owner 1",
            "company_id":   1,
            "passport":     "http://localhost/owners/1/passport.pdf"
        }
    }
    
`"passport"` is the url to the owner's passport in pdf format, if it exists. It can, of course, be retrieved using

    curl -i http://localhost/owners/1/passport.pdf

Writing
-------

To create, edit og delete a company, or to add, edit or delete its corresponding owners, we use the same URLs using different HTTP methods. For instance, we can create a new company using the `POST` method on `http://localhost/companies`, providing the desired attributes in JSON format.

    $ curl -i -X POST http://localhost/companies --data '
        {
            "company":{
                "name": "New Company",
                ...
            }
        }'
        
The server then returns the newly created company in JSON format, including its new `id`, which the client needs in order to add owners.

Similarly we can update an existing company using the `PUT` method on a specific company url.

    $ curl -i -X PUT http://localhost/companies/1 --data '
        {
            "company":{
                "name": "Updated Company",
                ...
            }
        }'
        
if we ever supply an `id`, when creating or updating records, it will simply be ignored.

To delete a company, we use the HTTP `DELETE` method.

    $ curl -i -X DELETE http://localhost/companies/1
    
which on success sends a redirect header to the `/companies` index page.

Owners
------

Owners are read and written in the same manner as companies:

 -  `GET /owners` returns a list of all owners. A list of specific `id`'s     can be supplied as an array in the query string:  
    `GET /owners?ids[]=1&ids[]=3&ids[]=5`.  
    This is useful if the client wants all owners belonging to a specific     company.
 -  `GET /owners/<id>` returns the owner with id `<id>`.
 -  `GET /owners/<id>/passport.pdf` returns the owner's passport as a PDF     file if it exists, otherwise 404.
 -  `POST /owners` creates a new owner using the given JSON data.
 -  `PUT /owners/<id>` updates a given owner using the given JSON data.
 -  `DELETE /owners/<id>` deletes a given owner.
 
In order to attach a PDF passport for a given owner, the client includes the content of the file, Base64URL-encoded, in the JSON data as the attribute `"passport_file"`. The server then decodes and saves the file, and the response contains the URI (`"password"`) for the PDF document.

Status codes
------------

As a rule of thumb, the server responds

 - 200 if everything went well
 - 404 if the page was not found or a given resource does not exist
 - 400 if the request was not understood, for example if the passport file is wrongly formatted
 - 500 if an unexpected server error occured.


<link rel="stylesheet" href="css/bootstrap.css"></link>
