# Introduction

The ASP.NET Core documentation includes a 
[tutorial](https://docs.microsoft.com/en-us/aspnet/core/tutorials/first-mvc-app/start-mvc?view=aspnetcore-5.0&tabs=visual-studio) 
on how to build a simple movie database.

This tutorial guides you through building the same tutorial in
F# and the [Saturn](https://saturnframework.org/) web framework.



# Project directory

Go to the directory where our project will be created.

```sh
cd C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn
```



Create the project directory and change to it.

    mkdir MvcMovieSaturn

    cd MvcMovieSaturn
    
Setup git.

    git init

    dotnet new gitignore

    git add .

    git commit -m 'Initial checkin'

Install the Saturn template

    dotnet new -i Saturn.Template

Create a new saturn project.

    dotnet new saturn

    Remove-Item global.json

    dotnet tool restore

    git add . 

    git commit -m 'dotnet new saturn'

Use `saturn gen` to generate project files from a template.

    dotnet saturn gen Movie Movies Id:int Title:string ReleaseDate:DateTime Genre:string Price:decimal Rating:string

    dotnet saturn migration

# Build issues

At this point, if you run the program:

    dotnet fake build -t run

you may see something like the following:

    C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\Movies\MoviesModel.fs(16,26): error FS0001: The type 'int' does not have 'null' as a proper value [C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\MvcMovieSaturn.fsproj]
    C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\Movies\MoviesViews.fs(35,73): error FS0039: The type 'Movie' does not define the field, constructor or member 'id'. [C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\MvcMovieSaturn.fsproj]
    C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\Movies\MoviesViews.fs(36,71): error FS0039: The type 'Movie' does not define the field, constructor or member 'id'. [C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\MvcMovieSaturn.fsproj]
    C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\Movies\MoviesViews.fs(37,94): error FS0039: The type 'Movie' does not define the field, constructor or member 'id'. [C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\MvcMovieSaturn.fsproj]
    C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\Movies\MoviesViews.fs(62,61): error FS0039: The type 'Movie' does not define the field, constructor or member 'id'. [C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\MvcMovieSaturn.fsproj]
    C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\Movies\MoviesViews.fs(101,67): error FS0039: The type 'Movie' does not define the field, constructor or member 'id'. [C:\Users\dharm\Dropbox\Documents\VisualStudio\MvcMovieSaturn\src\MvcMovieSaturn\MvcMovieSaturn.fsproj]

The `saturn gen` tool currently is quite simple. It assumes that:
- the id field will be called `id`
- the id field will be a string

Above, we called the field `Id` and specified it to have type `int`.

Let's update the generated code accordingly.


---
File: `.\src\MvcMovieSaturn\Movies\MoviesModel.fs`

Original text: 
```
    let validators = [
      fun u -> if isNull u.Id then Some ("Id", "Id shouldn't be empty") else None
    ]
```

Replacement text: 
```
    let validators = []
```



---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
o.id
```

Replacement text: 
```
o.Id
```





---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
o.Value.id
```

Replacement text: 
```
o.Value.Id
```


# SQLite Autoincrement

Saturn currently uses SQLite as its database.
Now that we've setup `Id` to be an integer, let's also make it 
[autoincrement](https://sqlite.org/autoinc.html).


---
File: `.\src\Migrations\*.Movie.fs`

Original text: 
```
Id INT NOT NULL
```

Replacement text: 
```
Id INTEGER PRIMARY KEY
```


Rebuild the database

    Remove-Item .\src\MvcMovieSaturn\database.sqlite

    dotnet saturn migration

# Router.fs


---
File: `.\src\MvcMovieSaturn\Router.fs`

Original text: 
```
    forward "" defaultView //Use the default view
```

Replacement text: 
```
    forward "" defaultView //Use the default view
    forward "/movies" Movies.Controller.resource
```


Build the project:

    dotnet fake build

# Running the web app

In a new console window, run the following:

    dotnet fake build -t run

This will run the web app. It will also watch the project for any changes.
When a file changes, the project will be rebuilt.
You may want to leave this running in this separate window.
 
Open the site:

    http://localhost:8085/

As well as the movies list:

    http://localhost:8085/movies

# Create a canopy project for testing the web app

[Canopy](https://lefthandedgoat.github.io/canopy/index.html)
is a web testing framework written in F#.

    dotnet new console --language f# --output src/Test
    
    dotnet sln MvcMovieSaturn.sln add src/Test
    
    dotnet add src/Test/Test.fsproj package canopy
    
    dotnet add src/Test/Test.fsproj package Selenium.WebDriver.ChromeDriver

## Setup the first unit test

File: `src/Test/Program.fs`

```
open canopy.runner.classic
open canopy.configuration
open canopy.classic

canopy.configuration.chromeDir <- System.AppContext.BaseDirectory

start chrome

"taking canopy for a spin" &&& fun _ ->

    url "http://localhost:8085/movies"

    waitForElement ".navbar"

    "tbody" == ""

    "th" *= "Id"
    "th" *= "Title"
    
run()

quit()
```

## Running the tests

Reset the database:

    Remove-Item .\src\MvcMovieSaturn\database.sqlite
    dotnet saturn migration

Run the tests:

    dotnet run --project .\src\Test\Test.fsproj

In this tutorial, whenever you see the following:

    test-app

I'll assume you've reset the database and run the tests.

Let's check-in our work so far.

    git add . ; git commit -m 'movies'

Let's add a step to the tests which adds a movie.


---
File: `.\src\Test\Program.fs`

Original text: 
```
"tbody" == ""
```

Replacement text: 
```
// "tbody" == ""
```




---
File: `.\src\Test\Program.fs`

Original text: 
```
run()
```

Replacement text: 
```
    click "New Movie"
    
    "/html/body/section/div/form/div[1]/div/input" << "1"
    "/html/body/section/div/form/div[2]/div/input" << "Fist of Fury"
    "/html/body/section/div/form/div[3]/div/input" << "1977-01-02"
    "/html/body/section/div/form/div[4]/div/input" << "Kung Fu"
    "/html/body/section/div/form/div[5]/div/input" << "1.23"
    "/html/body/section/div/form/div[6]/div/input" << "Awesome"

    sleep 2

    click "Submit"

    sleep 2

    "/html/body/section/div/table/tbody/tr[1]/td[5]" == "1.23" // check price value on resulting page


    click "/html/body/section/div/table/tbody/tr[1]/td[7]/a[1]" // click show

    sleep 2

run()
```


Let's test the app

    test-app

When the user clicks on 'Show', an error shows up:

    Must add values for the following parameters: @Id

Let's fix the issue:


---
File: `.\src\MvcMovieSaturn\Movies\MoviesRepository.fs`

Original text: 
```
  let getById connectionString id : Task<Result<Movie option, exn>> =
    task {
      use connection = new SqliteConnection(connectionString)
      return! querySingle connection "SELECT Id, Title, ReleaseDate, Genre, Price, Rating FROM Movies WHERE Id=@Id" (Some <| dict ["id" => id])
    }
```

Replacement text: 
```
  let getById connectionString id : Task<Result<Movie option, exn>> =
    task {
      use connection = new SqliteConnection(connectionString)
      return! querySingle connection "SELECT Id, Title, ReleaseDate, Genre, Price, Rating FROM Movies WHERE Id=@Id" (Some <| dict ["Id" => id])
    }
```


    test-app

Looks good. Let's add a test for this.


---
File: `.\src\Test\Program.fs`

Original text: 
```
run()
```

Replacement text: 
```
    "/html/body/section/div/h2" == "Show Movie"
    
    contains "Fist of Fury" (read "/html/body/section/div/ul/li[2]")

run()
```


And run the new test.

    test-app

    git add . ; git commit -m 'fix show issue'
    
# Deleting a movie

Try to delete a movie. You'll not it is not removed.

We'll add a step to the tests which clicks `Delete` for us.


---
File: `.\src\Test\Program.fs`

Original text: 
```
run()
```

Replacement text: 
```
    url "http://localhost:8085/movies"

    click "Delete"

run()
```


    test-app

Let's fix the issue.
We'll change `id` to `Id` in the delete method.


---
File: `.\src\MvcMovieSaturn\Movies\MoviesRepository.fs`

Original text: 
```
  let delete connectionString id : Task<Result<int,exn>> =
    task {
      use connection = new SqliteConnection(connectionString)
      return! execute connection "DELETE FROM Movies WHERE Id=@Id" (dict ["id" => id])
    }
```

Replacement text: 
```
  let delete connectionString id : Task<Result<int,exn>> =
    task {
      use connection = new SqliteConnection(connectionString)
      return! execute connection "DELETE FROM Movies WHERE Id=@Id" (dict ["Id" => id])
    }
```


    test-app

Looks good. Let's add a test for this.


---
File: `.\src\Test\Program.fs`

Original text: 
```
run()
```

Replacement text: 
```
    "tbody" == ""

run()
```


    test-app

# Id field in forms

The create and edit forms should not show a field for 'Id'. Currently they do.
Let's take care of this.



---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
          yield field (fun i -> (string i.Id)) "Id" "Id" 
```

Replacement text: 
```

          if isUpdate then
          
            yield input [
              _type "hidden"
              _name "Id"
              _value (defaultArg (o |> Option.map (fun i -> (string i.Id))) "")
            ]

          else
            yield div [] []

```


Let's also remove the previous line in the tests file which sets the Id field.


---
File: `.\src\Test\Program.fs`

Original text: 
```
"/html/body/section/div/form/div[1]/div/input" << "1"
```

Replacement text: 
```
// "/html/body/section/div/form/div[1]/div/input" << "1"
```


    test-app

Looks good. Let's add a test for this.


---
File: `.\src\Test\Program.fs`

Original text: 
```
run()
```

Replacement text: 
```
    // Make sure that there's no label for 'Id'

    url "http://localhost:8085/movies/add"

    "label" *!= "Id"

    sleep 1

    "/html/body/section/div/form/div[2]/div/input" << "Enter the Dragon"
    "/html/body/section/div/form/div[3]/div/input" << "1978-01-02"
    "/html/body/section/div/form/div[4]/div/input" << "Kung Fu"
    "/html/body/section/div/form/div[5]/div/input" << "2.34"
    "/html/body/section/div/form/div[6]/div/input" << "Awesome"

    sleep 1

    click "Submit"    

    sleep 1

run()
```


    test-app

# Adding another movie

Adding a second movie causes an error:

    SQLite Error 19: 'UNIQUE constraint failed: Movies.Id'.

Let's fix this.


---
File: `.\src\MvcMovieSaturn\Movies\MoviesRepository.fs`

Original text: 
```
  let insert connectionString v : Task<Result<int,exn>> =
    task {
      use connection = new SqliteConnection(connectionString)
      return! execute connection "INSERT INTO Movies(Id, Title, ReleaseDate, Genre, Price, Rating) VALUES (@Id, @Title, @ReleaseDate, @Genre, @Price, @Rating)" v
    }
```

Replacement text: 
```
  let insert connectionString v : Task<Result<int,exn>> =
    task {
      use connection = new SqliteConnection(connectionString)
      return! execute connection "INSERT INTO Movies(Title, ReleaseDate, Genre, Price, Rating) VALUES (@Title, @ReleaseDate, @Genre, @Price, @Rating)" v
    }
```


# Front page

Let's update the front page to match the same look as the ASP.NET MvcMovie project.

File: `.\src\MvcMovieSaturn\Templates\Index.fs`

```
module Index

open Giraffe.GiraffeViewEngine

let index =
    [
        div [ _class "text-center" ] [
            h1 [ _class "display-4 " ] [ rawText "Welcome" ]
            p [] [ 
                rawText "Learn about "
                a [ _href "https://docs.microsoft.com/aspnet/core" ] [ rawText "building Web apps with ASP.NET Core" ] 
            ]
        ]

    ]

let layout =
    App.layout index
```

# App.fs

The `App.fs` file is a template that is used for all pages on the site.

For now, we're replacing the body portion of this file.


---
File: `.\src\MvcMovieSaturn\Templates\App.fs`

Original text: 
```
        body [] [
            yield nav [ _class "navbar is-fixed-top has-shadow" ] [
                div [_class "navbar-brand"] [
                    a [_class "navbar-item"; _href "/"] [
                        img [_src "https://avatars0.githubusercontent.com/u/35305523?s=200"; _width "28"; _height "28"]
                    ]
                    div [_class "navbar-burger burger"; attr "data-target" "navMenu"] [
                        span [] []
                        span [] []
                        span [] []
                    ]
                ]
                div [_class "navbar-menu"; _id "navMenu"] [
                    div [_class "navbar-start"] [
                        a [_class "navbar-item"; _href "https://github.com/SaturnFramework/Saturn/blob/master/README.md"] [rawText "Getting started"]
                    ]
                ]
            ]
            yield! content
            yield footer [_class "footer is-fixed-bottom"] [
                div [_class "container"] [
                    div [_class "content has-text-centered"] [
                        p [] [
                            rawText "Powered by "
                            a [_href "https://github.com/SaturnFramework/Saturn"] [rawText "Saturn"]
                            rawText " - F# MVC framework created by "
                            a [_href "http://lambdafactory.io"] [rawText "λFactory"]
                        ]
                    ]
                ]
            ]
            yield script [_src "/app.js"] []
```

Replacement text: 
```
        body [] [

            yield header [] [

                nav [ _class "navbar navbar-expand-sm navbar-toggleable-sm navbar-light bg-white border-bottom box-shadow mb-3" ] [
                    div [ _class "container" ] [

                        a [ _class "navbar-brand"; _href "/movies" ] [ rawText "Movie App" ]
                        
                        button [ 
                            _class "navbar-toggler"; _type "button"; attr "data-toggle" "collapse"; attr "data-target" ".navbar-collapse"; 
                            attr "aria-controls" "navbarSupportedContent"; attr "aria-expanded" "false"; 
                            attr "aria-label" "Toggle navigation" 
                        ] [
                            span [ _class "navbar-toggler-icon" ] [ ] 
                        ]

                        div [ _class "navbar-collapse collapse d-sm-inline-flex flex-sm-row-reverse" ] [
                            ul [ _class "navbar-nav flex-grow-1" ] [
                                li [ _class "nav-item" ] [
                                    a [ _class "nav-link text-dark"; _href "/home" ] [ rawText "Home" ] ]
                                li [ _class "nav-item" ] [
                                    a [ _class "nav-link text-dark"; _href "/privacy" ] [
                                        rawText "Privacy" 
                                    ] 
                                ] 
                            ] 
                        ]
                    ]
                ]
            ]

            yield div [ _class "container" ] [
                main [ attr "role" "main"; _class "pb-3" ] [
                    yield! content
                ]
            ]

            yield footer [ _class "border-top footer text-muted" ] [
                div [ _class "container" ] [
                    rawText "&copy; 2020 - Movie App - "
                    a [ _href "/Home/Privacy" ] [ rawText "Privacy" ]
                ] 
            ]

            yield script [ _src "/app.js" ] []
```


Go to:

    http://localhost:8085/

The page doesn't look quite right.

# Install bootstrap

    Push-Location .\src\MvcMovieSaturn

    libman install twitter-bootstrap --provider cdnjs --destination static\lib\bootstrap

    Pop-Location

Let's update the CSS.
We'll remove the reference to `bulma` and use `bootstrap` instead.


---
File: `.\src\MvcMovieSaturn\Templates\App.fs`

Original text: 
```
            link [_rel "stylesheet"; _href "https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" ]
            link [_rel "stylesheet"; _href "https://cdnjs.cloudflare.com/ajax/libs/bulma/0.6.1/css/bulma.min.css" ]
            link [_rel "stylesheet"; _href "/app.css" ]
```

Replacement text: 
```
            link [ _rel "stylesheet"; _href "https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" ]
            link [ _rel "stylesheet"; _href "/lib/bootstrap/css/bootstrap.min.css" ]
            link [ _rel "stylesheet"; _href "/app.css" ]
```


Let's look at the result

    http://localhost:8085/

OK, that's better!

# Privacy page

File: `.\src\MvcMovieSaturn\Templates\Privacy.fs`

```
module Privacy

open Giraffe.GiraffeViewEngine

let privacy =
    [
        h1 [] [ rawText "Privacy Policy" ]

        p [] [ rawText "Use this page to detail your site's privacy policy." ]
    ]

let layout =
    App.layout privacy
```



---
File: `.\src\MvcMovieSaturn\MvcMovieSaturn.fsproj`

Original text: 
```
    <Compile Include="Templates\Index.fs" />
```

Replacement text: 
```
    <Compile Include="Templates\Index.fs" />
    <Compile Include="Templates\Privacy.fs" />
```




---
File: `.\src\MvcMovieSaturn\Router.fs`

Original text: 
```
    get "/default.html" (redirectTo false "/")
```

Replacement text: 
```
    get "/default.html" (redirectTo false "/")
    get "/privacy" (htmlView Privacy.layout)
```



# app.css

File: `.\src\MvcMovieSaturn\static\app.css`

```
/* This file is for your main application css. */

/* Please see documentation at https://docs.microsoft.com/aspnet/core/client-side/bundling-and-minification
for details on configuring this project to bundle and minify static web assets. */

a.navbar-brand {
    white-space: normal;
    text-align: center;
    word-break: break-all;
  }
  
  /* Provide sufficient contrast against white background */
  a {
    color: #0366d6;
  }
  
  .btn-primary {
    color: #fff;
    background-color: #1b6ec2;
    border-color: #1861ac;
  }
  
  .nav-pills .nav-link.active, .nav-pills .show > .nav-link {
    color: #fff;
    background-color: #1b6ec2;
    border-color: #1861ac;
  }
  
  /* Sticky footer styles
  -------------------------------------------------- */
  html {
    font-size: 14px;
  }
  @media (min-width: 768px) {
    html {
      font-size: 16px;
    }
  }
  
  .border-top {
    border-top: 1px solid #e5e5e5;
  }
  .border-bottom {
    border-bottom: 1px solid #e5e5e5;
  }
  
  .box-shadow {
    box-shadow: 0 .25rem .75rem rgba(0, 0, 0, .05);
  }
  
  button.accept-policy {
    font-size: 1rem;
    line-height: inherit;
  }
  
  /* Sticky footer styles
  -------------------------------------------------- */
  html {
    position: relative;
    min-height: 100%;
  }
  
  body {
    /* Margin bottom by footer height */
    margin-bottom: 60px;
  }
  .footer {
    position: absolute;
    bottom: 0;
    width: 100%;
    white-space: nowrap;
    line-height: 60px; /* Vertically center the text there */
  }
```

# Update Show, Edit, and Delete link labels


---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
                  a [_class "button is-text"; _href (Links.withId ctx o.Id )] [encodedText "Show"]
                  a [_class "button is-text"; _href (Links.edit ctx o.Id )] [encodedText "Edit"]
```

Replacement text: 
```
                  a [_class "button is-text"; _href (Links.withId ctx o.Id )] [encodedText "Show"]
                  encodedText " | "
                  a [_class "button is-text"; _href (Links.edit ctx o.Id )] [encodedText "Edit"]
                  encodedText " | "
```


# Formatting and validation

If you go to:

    http://localhost:8085/movies

you may notice that the column label for the release date is `ReleaseDate`.

Also, the release date is displayed with the time.

In ASP.NET Core, these issues are addressed using attributes on the `Movie` class along with Tag Helpers.

Saturn does not come with the equivalent of tag helpers. But, we'll use an 
experimental library which does some of what the ASP.NET Core Tag Helpers provides.

Open libraries needed for the attributes:


---
File: `.\src\MvcMovieSaturn\Movies\MoviesModel.fs`

Original text: 
```
namespace Movies
```

Replacement text: 
```
namespace Movies

open System.ComponentModel.DataAnnotations
```


Add the attributes


---
File: `.\src\MvcMovieSaturn\Movies\MoviesModel.fs`

Original text: 
```
  Title: string
  ReleaseDate: System.DateTime
```

Replacement text: 
```
  Title: string

  [<Display(Name = "Release Date")>]
  [<DataType(DataType.Date)>]
  ReleaseDate: System.DateTime

```


Add the experimental TagHelpers library.

I don't expect you to type this one in manually. 
Feel free to copy and paste it in.

File: `.\src\MvcMovieSaturn\TagHelpers.fs`

```
module MvcMovieGiraffe.TagHelpers

open System.Linq

open System.ComponentModel.DataAnnotations

// open Giraffe.ViewEngine

open Giraffe.GiraffeViewEngine

// ----------------------------------------------------------------------

open FSharp.Quotations
open FSharp.Quotations.Patterns

let (|PropInfo|_|) (e : Expr<'a>) =
    match e with
    | Patterns.PropertyGet (obj_instance, prop_info, _body_expressions) ->
        let getter =
            match obj_instance with
            | None                                -> fun () -> prop_info.GetValue(null)
            | Some (ValueWithName(v, _ty, _name)) -> fun () -> prop_info.GetValue(v)
            | _                                   -> fun () -> box null
        
        Some(prop_info, getter)

    | _ -> None

// ----------------------------------------------------------------------

[<RequireQualifiedAccess>]
type Input =
    static member Of([<ReflectedDefinition>] expr: Expr<'a>, attrs_a: XmlAttribute list) =
        match expr with
        | PropInfo(property_info, get_current_value) ->
                                                            
            let display_name =

                let cattr = System.Attribute.GetCustomAttribute(property_info, typedefof<DisplayAttribute>) :?> DisplayAttribute

                if (not (isNull cattr)) then
                    cattr.Name
                else
                    property_info.Name

            // System.Console.WriteLine(property_name + " : " + property_info.PropertyType.Name)
            
            let type_attribute_provided = attrs_a.Any(fun xml_attr ->
                match xml_attr with
                | KeyValue (attr_key, attr_val) -> attr_key = "type"
                | Boolean str -> false)

            let type_value =

                let data_type_attr = System.Attribute.GetCustomAttribute(property_info, typedefof<DataTypeAttribute>) :?> DataTypeAttribute

                if not type_attribute_provided then
                    if (not (isNull data_type_attr)) && (data_type_attr.DataType = DataType.Date) then
                        "date"
                    else
                        match property_info.PropertyType.Name with
                        | "Int64"    -> "number"
                        | "DateTime" -> "datetime-local"
                        | _          -> "text"
                else
                    "text"                

            let attrs_b =
                (
                    if not type_attribute_provided then
                        [ _type type_value ]
                    else
                        []                        
                )
                @
                [ attr "data-val" "true"]
                @
                (
                    match property_info.PropertyType.Name with
                    | "Int32"
                    | "DateTime" -> [ attr "data-val-required" (sprintf "The %s field is required." display_name) ]
                    | "Decimal"  ->
                        [
                            attr "data-val-number" (sprintf "The field %s must be a number." display_name)
                            attr "data-val-required" (sprintf "The %s field is required." display_name)
                        ]
                    | _ -> []
                )
                @
                (
                    let cattr = System.Attribute.GetCustomAttribute(property_info, typedefof<StringLengthAttribute>) :?> StringLengthAttribute

                    if (not (isNull cattr)) then
                        if (cattr.MinimumLength > 0) then
                            [
                                attr "data-val-length" (sprintf "The field %s must be a string with a minimum length of %i and a maximum length of %i." property_info.Name cattr.MinimumLength cattr.MaximumLength)
                                attr "data-val-length-max" (string cattr.MaximumLength)
                                attr "data-val-length-min" (string cattr.MinimumLength)
                                attr "maxlength" (string cattr.MaximumLength)
                            ]
                        else
                            [
                                attr "data-val-length" (sprintf "The field %s must be a string with a maximum length of %i." property_info.Name cattr.MaximumLength)
                                attr "data-val-length-max" (string cattr.MaximumLength)
                                attr "maxlength" (string cattr.MaximumLength)
                            ]
                    else []
                )
                @
                (
                    let cattr = System.Attribute.GetCustomAttribute(property_info, typedefof<RegularExpressionAttribute>) :?> RegularExpressionAttribute

                    if (not (isNull cattr)) then
                        [
                            attr "data-val-regex" (sprintf "The field %s must match the regular expression %s." property_info.Name cattr.Pattern)
                            attr "data-val-regex-pattern" cattr.Pattern
                        ]
                    else []
                )
                @
                (
                    let cattr = System.Attribute.GetCustomAttribute(property_info, typedefof<RangeAttribute>) :?> RangeAttribute

                    if (not (isNull cattr)) then
                        [
                            attr "data-val-range" (sprintf "The field %s must be between %s and %s." property_info.Name (string cattr.Minimum) (string cattr.Maximum))
                            attr "data-val-range-max" (string cattr.Maximum)
                            attr "data-val-range-min" (string cattr.Minimum)
                        ]
                    else []
                )
                @
                (
                    let cattr = System.Attribute.GetCustomAttribute(property_info, typedefof<RequiredAttribute>) :?> RequiredAttribute

                    if (not (isNull cattr)) then
                        [ attr "data-val-required" (sprintf "The %s field is required." property_info.Name) ]
                    else []                    
                )
                @
                [
                    _id property_info.Name
                    _name property_info.Name
                    _value
                        (
                            if type_value = "date" then
                                if (isNull (get_current_value())) then
                                    ""
                                else
                                    (get_current_value() :?> System.DateTime).ToString "yyyy-MM-dd"
                            else
                                (string (get_current_value()))
                        )

                ]                    
            
            input (attrs_a @ attrs_b)
            
        | _ -> failwith "tag helper issue"

// ----------------------------------------------------------------------

[<RequireQualifiedAccess>]
type SpanValidation =
    static member Of([<ReflectedDefinition>] expr: Expr<'a>, attrs_a: XmlAttribute list) =
        match expr with
        | PropInfo(property_info, get_current_value) ->

            let attrs_d =

                let has_class =
                    attrs_a.Any(fun xml_attr ->
                        match xml_attr with
                        | KeyValue (attr_key, attr_val) ->
                            if attr_key = "class" then
                                true
                            else
                                false
                        | Boolean str -> false
                    )

                if has_class then
                    attrs_a
                else
                    attrs_a @ [ _class "" ]


            let attrs_b = 
                attrs_d.Select(fun xml_attr -> 
                    match xml_attr with
                    | KeyValue (attr_key, attr_val) ->
                        if attr_key = "class" then
                            KeyValue (attr_key, attr_val + " field-validation-valid")
                        else
                            xml_attr
                    | Boolean str -> xml_attr
                )
            
            let attrs_c =
                [
                    attr "data-valmsg-for" property_info.Name
                    attr "data-valmsg-replace" "true"
                ]

            span ((List.ofSeq attrs_b) @ attrs_c) []
            
        | _ -> failwith "tag helper issue"

// ----------------------------------------------------------------------

[<RequireQualifiedAccess>]
type Label =
    static member Of([<ReflectedDefinition>] expr: Expr<'a>, attrs_a: XmlAttribute list) =
        match expr with
        | PropInfo(property_info, _) ->

            let display_name =

                let cattr = System.Attribute.GetCustomAttribute(property_info, typedefof<DisplayAttribute>) :?> DisplayAttribute

                if (not (isNull cattr)) then
                    cattr.Name
                else
                    property_info.Name        
            
            // System.Console.WriteLine(property_name + " : " + property_info.PropertyType.Name)

            label (attrs_a @ [ _for property_info.Name ]) [ encodedText display_name ]
        
        | _ -> failwith "tag helper issue"

// ----------------------------------------------------------------------

[<RequireQualifiedAccess>]
type Display =
    static member NameFor([<ReflectedDefinition>] expr: Expr<'a>) =
        match expr with
        | PropInfo(property_info, _) ->

            let display_name =

                let cattr = System.Attribute.GetCustomAttribute(property_info, typedefof<DisplayAttribute>) :?> DisplayAttribute

                if (not (isNull cattr)) then
                    cattr.Name
                else
                    property_info.Name        

            display_name
                    
        | _ -> failwith "tag helper issue"    

    static member For([<ReflectedDefinition>] expr: Expr<'a>) =
        match expr with
        | PropInfo(property_info, get_current_value) ->
                    
            let data_type_attr = System.Attribute.GetCustomAttribute(property_info, typedefof<DataTypeAttribute>) :?> DataTypeAttribute

            if (isNull data_type_attr) then
                get_current_value() |> string
            elif data_type_attr.DataType = DataType.Date then
                (get_current_value() :?> System.DateTime).ToString "d"
            elif data_type_attr.DataType = DataType.Currency then
                (get_current_value() :?> System.Decimal).ToString "C"
            else
                get_current_value() |> string
         
        | _ -> failwith "tag helper issue"    

```

Update MvcMovieSaturn.fsproj


---
File: `.\src\MvcMovieSaturn\MvcMovieSaturn.fsproj`

Original text: 
```
    <Compile Include="Config.fs" />

    <Compile Include="Templates\App.fs" />
```

Replacement text: 
```
    <Compile Include="Config.fs" />

    <Compile Include="TagHelpers.fs" />

    <Compile Include="Templates\App.fs" />
```


# Use the TagHelpers library


---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
th [] [encodedText "ReleaseDate"]
```

Replacement text: 
```
th [] [ encodedText (MvcMovieGiraffe.TagHelpers.Display.NameFor(Unchecked.defaultof<Movie>.ReleaseDate)) ]
```





---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
td [] [encodedText (string o.ReleaseDate)]
```

Replacement text: 
```
td [] [ encodedText (MvcMovieGiraffe.TagHelpers.Display.For o.ReleaseDate) ]
```


OK, now if you view the movie list:

    http://localhost:8085/movies

the column header and value for the release date are properly formatted.

# Create movie form - validation

Update 'add' body


---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
  let add (ctx: HttpContext) (o: Movie option) (validationResult : Map<string, string>)=
    form ctx o validationResult false
```

Replacement text: 
```
  let add (ctx: HttpContext) (o: Movie option) (validationResult : Map<string, string>)=
      App.layout [

          h1 [] [ encodedText "Create" ]

          h4 [] [ encodedText "Movie" ]

          hr []

          div [ _class "row" ] [
              div [ _class "col-md-4" ] [
                  Giraffe.GiraffeViewEngine.form [ 
                      _action "/movies/"; 
                      _method "post" 
                    ] [

                      let form_group (expr : FSharp.Quotations.Expr<'a>) =
                          div [ _class "form-group" ] [
                              MvcMovieGiraffe.TagHelpers.Label.Of(%expr, [ _class "control-label" ])

                              MvcMovieGiraffe.TagHelpers.Input.Of(%expr, [ _class "form-control" ])

                              MvcMovieGiraffe.TagHelpers.SpanValidation.Of(%expr, [ _class "text-danger" ])
                          ]

                      form_group <@ Unchecked.defaultof<Movie>.Title @>
                      form_group <@ Unchecked.defaultof<Movie>.ReleaseDate @>
                      form_group <@ Unchecked.defaultof<Movie>.Genre @>
                      form_group <@ Unchecked.defaultof<Movie>.Price @>
                      form_group <@ Unchecked.defaultof<Movie>.Rating @>

                      div [ _class "form-group" ] [
                        input [ _type "submit"; _value "Create"; _class "btn btn-primary" ]
                      ]
                  ]
              ]
          ]      
      ]
```


The jquery validation scripts are needed.

Install jquery and jquery validation libraries

    Push-Location .\src\MvcMovieSaturn
    
    libman install jquery                        --provider cdnjs --destination static/lib/jquery
    libman install jquery-validate               --provider cdnjs --destination static/lib/jquery-validate
    libman install jquery-validation-unobtrusive --provider cdnjs --destination static/lib/jquery-validation-unobtrusive
    
    Pop-Location

Update layout to accept additional parameter for scripts.


---
File: `.\src\MvcMovieSaturn\Templates\App.fs`

Original text: 
```
let layout (content: XmlNode list) =
```

Replacement text: 
```
let layout (content: XmlNode list) (scripts : XmlNode list) =
```


Reference jquery as well as the new 'scripts' parameter.


---
File: `.\src\MvcMovieSaturn\Templates\App.fs`

Original text: 
```
            yield script [ _src "/app.js" ] []
```

Replacement text: 
```
            yield script [ _src "/app.js" ] []

            yield script [ _src "/lib/jquery/jquery.min.js" ] []

            yield! scripts
```


Update calls to `App.layout` to value to new parameter.


---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
    App.layout ([section [_class "section"] cnt])
```

Replacement text: 
```
    App.layout ([section [_class "section"] cnt]) []
```





---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
      ]

  let edit (ctx: HttpContext) (o: Movie) (validationResult : Map<string, string>) =
    form ctx (Some o) validationResult true
```

Replacement text: 
```
      ] [
          script [ _src "/lib/jquery-validate/jquery.validate.min.js" ] []
          script [ _src "/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js" ] []          
      ]


  let edit (ctx: HttpContext) (o: Movie) (validationResult : Map<string, string>) =
    form ctx (Some o) validationResult true
```









---
File: `.\src\MvcMovieSaturn\Templates\Privacy.fs`

Original text: 
```
    App.layout privacy
```

Replacement text: 
```
    App.layout privacy []
```





---
File: `.\src\MvcMovieSaturn\Templates\Index.fs`

Original text: 
```
    App.layout index
```

Replacement text: 
```
    App.layout index []
```




OK, now to the add movie page:

    http://localhost:8085/movies/add

If you hit 'Create' without submitting the form, validation messages should appear for the release date and price fields.


# Attributes on the rest of the Movie fields


---
File: `.\src\MvcMovieSaturn\Movies\MoviesModel.fs`

Original text: 
```
open System.ComponentModel.DataAnnotations
```

Replacement text: 
```
open System.ComponentModel.DataAnnotations
open System.ComponentModel.DataAnnotations.Schema
```





---
File: `.\src\MvcMovieSaturn\Movies\MoviesModel.fs`

Original text: 
```
type Movie = {
  Id: int
  Title: string

  [<Display(Name = "Release Date")>]
  [<DataType(DataType.Date)>]
  ReleaseDate: System.DateTime

  Genre: string
  Price: decimal
  Rating: string
}
```

Replacement text: 
```
type Movie = {
  Id: int

  [<StringLength(60, MinimumLength = 3)>]
  [<Required>]  
  Title: string

  [<Display(Name = "Release Date")>]
  [<DataType(DataType.Date)>]
  ReleaseDate: System.DateTime

  [<RegularExpression(@"^[A-Z]+[a-zA-Z]*$")>]
  [<Required>]
  Genre: string

  [<Range(1, 100)>]
  [<DataType(DataType.Currency)>]
  [<Column(TypeName = "decimal(18, 2)")>]
  Price: decimal

  [<RegularExpression(@"^[A-Z]+[a-zA-Z0-9-]*$")>]
  [<StringLength(5)>]
  [<Required>]
  Rating: string
}
```


# Validation for edit form


---
File: `.\src\MvcMovieSaturn\Movies\MoviesViews.fs`

Original text: 
```
  let edit (ctx: HttpContext) (o: Movie) (validationResult : Map<string, string>) =
    form ctx (Some o) validationResult true
```

Replacement text: 
```
  let edit (ctx: HttpContext) (o: Movie) (validationResult : Map<string, string>) =
      App.layout [

          h1 [] [ encodedText "Edit" ]

          h4 [] [ encodedText "Movie" ]

          hr []

          div [ _class "row" ] [
              div [ _class "col-md-4" ] [
                  Giraffe.GiraffeViewEngine.form [ _action ("/movies/" + (string o.Id) + "/edit" ); _method "post" ] [
                      MvcMovieGiraffe.TagHelpers.Input.Of(o.Id, [ _type "hidden" ])

                      let form_group (expr : FSharp.Quotations.Expr<'a>) =
                          div [ _class "form-group" ] 
                              [
                                  MvcMovieGiraffe.TagHelpers.Label.Of(         %expr, [ _class "control-label" ])
                                  MvcMovieGiraffe.TagHelpers.Input.Of(         %expr, [ _class "form-control" ])
                                  MvcMovieGiraffe.TagHelpers.SpanValidation.Of(%expr, [ _class "text-danger" ])
                              ]

                      form_group <@ o.Title @>
                      form_group <@ o.ReleaseDate @>
                      form_group <@ o.Genre @>
                      form_group <@ o.Price @>
                      form_group <@ o.Rating @>

                      div [ _class "form-group" ] [
                          input [ _type "submit"; _value "Save"; _class "btn btn-primary" ]
                      ]

                      input [ _name "__RequestVerificationToken"; _type "hidden"; _value "..." ]
                  ]
              ]
          ]

          div [] [
              a [ _href "/Movies" ] [ encodedText "Back to List" ]
          ]          

      ] [
          script [ _src "/lib/jquery-validate/jquery.validate.min.js" ] []
          script [ _src "/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js" ] []          
      ]
```


# Update tests




File: `src/Test/Program.fs`

```
open canopy.runner.classic
open canopy.configuration
open canopy.classic

canopy.configuration.chromeDir <- System.AppContext.BaseDirectory

start chrome

"load main page" &&& fun _ ->
    url "http://localhost:8085/movies"

    waitForElement ".navbar"

    "th" *= "Id"
    "th" *= "Title"    

"create movie" &&& fun _ ->

    url "http://localhost:8085/movies"
    
    click "New Movie"
    
    "/html/body/div/main/div/div/form/div[1]/input" << "Fist of Fury"
    "/html/body/div/main/div/div/form/div[2]/input" << "1977-01-02"
    "/html/body/div/main/div/div/form/div[3]/input" << "KungFu"
    "/html/body/div/main/div/div/form/div[4]/input" << "1.23"
    "/html/body/div/main/div/div/form/div[5]/input" << "A"

    sleep 2

    click "Create"

    sleep 2

    "/html/body/div/main/section/div/table/tbody/tr/td[5]" == "1.23" // check price value on resulting page

"'show' movie" &&& fun _ ->

    url "http://localhost:8085/movies"

    click "/html/body/div/main/section/div/table/tbody/tr/td[7]/a[1]" // click show

    sleep 2

    "/html/body/div/main/section/div/h2" == "Show Movie"
        
    contains "Fist of Fury" (read "/html/body/div/main/section/div/ul/li[2]")

"'delete' movie" &&& fun _ ->

    url "http://localhost:8085/movies"

    click "Delete"

    "tbody" == ""

"'Id' label is hidden on add page" &&& fun _ ->

    url "http://localhost:8085/movies/add"

    "label" *!= "Id"

    sleep 1

"Add a second movie" &&& fun _ ->

    url "http://localhost:8085/movies/add"

    "/html/body/div/main/div/div/form/div[1]/input" << "Enter the Dragon"
    "/html/body/div/main/div/div/form/div[2]/input" << "1978-01-02"
    "/html/body/div/main/div/div/form/div[3]/input" << "KungFu"
    "/html/body/div/main/div/div/form/div[4]/input" << "2.34"
    "/html/body/div/main/div/div/form/div[5]/input" << "A"

    sleep 1

    click "Create"    

    sleep 1    

    "/html/body/div/main/section/div/table/tbody/tr/td[5]" == "2.34" // check price value on resulting page

run()

quit()

```

    test-app





