# ბეწვი - ტესტირება

პრაქტიკული 3. სისტემა: ვეტკლინიკების მართვის SaaS, .NET 8 + Angular.

ნაკრები: **226 ტესტი** (224 გადის, 2 გამოტოვებული), xUnit + WebApplicationFactory.

---

## 1. ტესტ-სცენარები საზღვრის შემთხვევებით

საზღვრები იმიტომ, რომ შეცდომა თითქმის ყოველთვის კიდეზეა და არა შუაში. თუ
ფუნქცია 1-დან 10-მდე მუშაობს, 5 არავის აინტერესებს: საინტერესოა 0, 1, 10, 11
და უარყოფითი.

### მედიკამენტის ჩამოწერა ვიზიტზე (ნაშთი 10)

| # | შემთხვევა | მოსალოდნელი | რატომ |
|---|---|---|---|
| 1 | -5 | 400 | უარყოფითი გამოკლება ნაშთს **ზრდის**: 10 - (-5) = 15 |
| 2 | 0 | 400 | უაზრო ჩანაწერი |
| 3 | 1 | 200, ნაშთი 9 | ყველაზე პატარა ნამდვილი |
| 4 | 10 | 200, ნაშთი 0 | ზუსტად ზღვარი |
| 5 | 11 | **200**, ნაშთი -1 | ნაშთი განზრახ შეიძლება გახდეს უარყოფითი |

მეხუთე ის შემთხვევაა, რომელიც ვარაუდით რომ დაგვეწერა, ტესტი ცდებოდა და არა
კოდი. `VisitMedicationsController`-ში კომენტარი ხსნის: წამალი ექიმს უკვე ხელში
უჭირავს, უარის თქმა მხოლოდ იმას გამოიწვევს, რომ პერსონალი სხვა რამედ ჩაწერს.
უარყოფითი ციფრი შეცდომას აჩენს, დამალვის ნაცვლად.

### ვიზიტის დანიშვნის დრო

| # | შემთხვევა | მოსალოდნელი | რატომ |
|---|---|---|---|
| 6 | 25 საათით ადრე | 400 | აკრეფის შეცდომა |
| 7 | 9 საათით ადრე | 200 | ექიმმა დილით მიიღო, საღამოს ჩაწერა |
| 8 | ზუსტად ერთი წლის შემდეგ | 200 | ვაქცინაციას სისტემა თვითონ ნიშნავს წელიწადში |
| 9 | 19 თვის შემდეგ | 400 | 2026-ის ნაცვლად 2028 აკრიფეს |
| 10 | შაბათი | 200 | კლინიკას სადღეღამისო მორიგეობა აქვს |
| 11 | 31 თებერვალი | 400 | არარსებული თარიღი |

### სხვა კლინიკის ჩანაწერი

| # | შემთხვევა | მოსალოდნელი |
|---|---|---|
| 12 | კლინიკა A ითხოვს კლინიკა B-ს პაციენტს | 404 |
| 13 | კლინიკა A ცდილობს B-ს ვიზიტის შეცვლას | 404 |

---

## 2. Unit-ტესტები AAA სტრუქტურით

**AAA = Arrange, Act, Assert.** მოამზადე, შეასრულე, შეამოწმე. ცარიელი ხაზები
სამ ნაწილს მიჯნავს.

```csharp
[Fact]
public async Task ANewProcedureIsOnOffer()
{
    // Arrange
    var token = await TestHelpers.GetTokenAsync(_client);

    // Act
    var t = await CreateAsync(token, $"ოვარიექტომია {Guid.NewGuid():N}");

    // Assert
    Assert.True(bool.Parse(t["isActive"].ToString()!));
}
```

ხუთი მაგალითი ნაკრებიდან:

| ტესტი | ფაილი | რას ამოწმებს |
|---|---|---|
| `ANewProcedureIsOnOffer` | `SurgeryTypeTests.cs` | ახალი პროცედურა აქტიურია |
| `AProcedureNeedsAName` | `SurgeryTypeTests.cs` | ცარიელი სახელი 400 |
| `AClinicAdminCannotReadTheAuditLog` | `AuditAccessTests.cs` | ადმინსაც კი ეკრძალება |
| `TheFileIsAWorkbookRatherThanCommaSeparatedText` | `ExportTests.cs` | ექსპორტი .xlsx და არა CSV |
| `TheMostSevereComesFirst` | `AnnouncementTests.cs` | კრიტიკული შეტყობინება პირველია |
| `Create_MoreThanADayInThePast_Returns400` | `VisitsTests.cs` | ქვემოთ, TDD-ის ნაწილში |

---

## 3. TDD ციკლი: ვიზიტის თარიღის ვალიდაცია

არჩეული ფუნქცია: **როდის შეიძლება ვიზიტის დანიშვნა.** წესი არ არსებობდა, ანუ
ნამდვილი TDD გამოვიდა და არა უკუსვლით დაწერილი ტესტი.

### წესი, რომელიც ჯერ გადავწყვიტეთ

| | ზღვარი | რატომ |
|---|---|---|
| წარსული | 24 საათი | ექიმმა დილით მიიღო, საღამოს ჩაწერა - ნორმაა. ერთ დღეზე ძველი - შეცდომა |
| მომავალი | 18 თვე | ვაქცინაცია ზუსტად წელიწადში ინიშნება, უფრო მკაცრი ზღვარი საკუთარ ფუნქციას დაბლოკავდა |

### 🔴 Red

```csharp
[Fact]
public async Task Create_MoreThanADayInThePast_Returns400()
{
    // Arrange
    var token  = await TestHelpers.GetTokenAsync(_client);
    var tooOld = DateTime.Now.AddHours(-25);

    // Act
    var res = await PostVisitAsync(token, tooOld);

    // Assert
    Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
}
```

`-25` და არა `-48`: ზღვართან რაც შეიძლება ახლოს, რომ ზუსტად ზღვარი შემოწმდეს.

გაშვების შედეგი:

```
Create_MoreThanADayInThePast_Returns400          [FAIL]
Create_MoreThanEighteenMonthsAhead_Returns400    [FAIL]

Assert.Equal() Failure: Values differ
Expected: BadRequest
Actual:   OK

Failed: 2, Passed: 6, Total: 8
```

**წითელი სწორი მიზეზით.** ტესტი გაეშვა, სერვერამდე მივიდა და თქვა "მოველოდი
400-ს, მივიღე 200". ეს ამტკიცებს, რომ ფუნქცია აკლია - და არა იმას, რომ ტესტი
ვერ ჩაეშვა.

ორივე მხარე დაიწერა: ორი ტესტი 400-ს ელოდება, ორი 200-ს. ბოლო ორი მაშინვე
გაიარა, რაც ამტკიცებს, რომ ტესტის ინფრასტრუქტურა მუშაობს.

### 🟢 Green

```csharp
private const int PastGraceHours = 24;
private const int FutureLimitMonths = 18;

private static bool ScheduledTooFarOut(DateTime scheduledAt, out string? error)
{
    var nowTbilisi = DateTime.UtcNow.AddHours(4);

    if (scheduledAt < nowTbilisi.AddHours(-PastGraceHours))
    {
        error = $"ვიზიტის თარიღი {PastGraceHours} საათზე ძველია";
        return true;
    }

    if (scheduledAt > nowTbilisi.AddMonths(FutureLimitMonths))
    {
        error = $"ვიზიტის თარიღი {FutureLimitMonths} თვეზე შორსაა";
        return true;
    }

    error = null;
    return false;
}
```

`Create`-ში, ყველაზე თავში:

```csharp
if (ScheduledTooFarOut(dto.ScheduledAt, out var whenError))
    return BadRequest(new { message = whenError });
```

```
Passed! - Failed: 0, Passed: 8, Total: 8
```

### 🔵 Refactor

შემოწმება ცალკე მეთოდად გავიტანე და ციფრები კონსტანტებში. `Create` უკვე
გრძელი იყო; ორი `if` პირდაპირ მასში მესამე პასუხისმგებლობას დაამატებდა.

ციფრები კონსტანტებად იმიტომ, რომ ისინი **პროდუქტის გადაწყვეტილებაა** და არა
ტექნიკური დეტალი. როცა კლინიკა იტყვის "48 საათი გვინდა", ერთი ხაზი შეიცვლება.

სასაათო სარტყელი ცალკე ღირს ახსნა: კლიენტები ადგილობრივ დროს აგზავნიან `Z`-ის
გარეშე, სერვერი კი Railway-ზე UTC-ზეა. ამიტომ "ახლა" იმავე კედლის საათით
ითვლება, `UtcNow.AddHours(4)`. საქართველო ზაფხულის დროზე არ გადადის, ამიტომ
ფიქსირებული სხვაობა საკმარისია.

სრული ნაკრები ცვლილების შემდეგ: **226 ტესტი, 224 გავლილი, 0 ჩავარდნილი.**

---

## 4. Integration-ტესტი ბაზით

Unit-ტესტისგან განსხვავება: აქ ნამდვილი HTTP მოთხოვნა მიდის ნამდვილ
აპლიკაციაში, გაივლის ავტორიზაციას, კონტროლერს, EF Core-ს და ბაზას.

`BetsviFactory : WebApplicationFactory<Program>` ქმნის აპლიკაციას მეხსიერებაში,
ნამდვილ ბაზას InMemory-ით ანაცვლებს და თითოეულ ტესტ-კლასს თავისი ბაზა აქვს:

```csharp
var dbName = "BetsviTest-" + Guid.NewGuid();
services.AddDbContext<BetsviDbContext>(opts => opts.UseInMemoryDatabase(dbName));
```

მაგალითი - მულტი-ტენანტობის შემოწმება, რაც მხოლოდ ბაზით შეიძლება:

```csharp
[Fact]
public async Task CannotEditAnotherClinicsCatalogue()
{
    // Arrange
    var token = await TestHelpers.GetTokenAsync(_client);

    // Act
    var res = await SendAsync(HttpMethod.Put, "/api/SurgeryTypes/999999",
        new { name = "x", description = (string?)null, defaultPrice = 1m }, token);

    // Assert
    Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
}
```

ეს global query filter-ს ამოწმებს: ჩანაწერი ბაზაში არსებობს, მაგრამ სხვა
კლინიკას ეკუთვნის, ამიტომ ამ მომხმარებლისთვის არ არსებობს.

---

## 6. Coverage და უტესტო ადგილი

```
dotnet test --collect:"XPlat Code Coverage" -- xUnit.ParallelizeTestCollections=false
```

> პარალელიზმის გამორთვა აუცილებელია: ათეულობით `WebApplicationFactory`
> ერთდროულად coverage-ის მონაცემს კარგავს და ანგარიში 0%-ს აჩვენებს.

| საქაღალდე | დაფარული | სულ | % |
|---|---|---|---|
| Controllers | 2214 | 5887 | 37.6% |
| Models | 385 | 448 | 85.9% |
| Data | 321 | 385 | 83.4% |
| Dtos | 129 | 209 | 61.7% |
| **Services** | **47** | **1387** | **3.4%** |
| **Authorization** | **0** | **33** | **0.0%** |
| Migrations | 0 | 62276 | 0.0% |

**სულ, მიგრაციების გარეშე: 3264 / 8586 = 38.0%**

მიგრაციები ამოღებულია: ისინი EF-ის ავტომატურად გენერირებული 62 ათასი ხაზია და
მათ ტესტირებას აზრი არ აქვს. მათთან ერთად ციფრი 4.6% იქნებოდა და არაფერს
გვეტყოდა.

### უტესტო ადგილი: `RequireModuleAttribute`

**0% დაფარვა, 33 ხაზი.** `Authorization/RequireModuleAttribute.cs`.

ეს არის ზუსტად ის design pattern, რომელიც არქიტექტურის დავალებაში backend-ის
მთავარ პატერნად წარვადგინე. ის წყვეტს, ჩართული აქვს თუ არა კლინიკას მოდული, და
ათეულობით endpoint-ს იცავს.

რისკი: თუ `superadmin`-ის შემოწმება გაფუჭდა, ან `ClinicId`-ის წაკითხვა შეიცვალა,
**არცერთი ტესტი არ გაწითლდება.** გათიშული მოდულის endpoint-ები ჩუმად გაიხსნება.

რა ტესტები აკლია:

| სცენარი | მოსალოდნელი |
|---|---|
| მოდული ჩართულია | endpoint პასუხობს |
| მოდული გათიშულია | 403 |
| superadmin, მოდული გათიშული | გადის |
| `ClinicId` claim არ არის | 403 |

ყველაზე დიდი აბსოლუტური ხარვეზები: `SuperAdminController` (625 ხაზი, 0%) და
`ImportController` (595 ხაზი, 0%). ორივე სახიფათოა - პირველი პლატფორმის მართვაა,
მეორე მონაცემების მასობრივი შემოტანა.
