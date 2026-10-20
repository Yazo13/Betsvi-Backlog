# ბეწვი - პროდუქტის დოკუმენტაცია

ვეტერინარული კლინიკების მართვის სისტემა. აქ დევს პროდუქტის ბექლოგი და
არქიტექტურის აღწერა.

პროდუქტის საიტი: betsvi.ge

---

## 1. პროდუქტის ბექლოგი

stakeholder-ები, user story-ები acceptance criteria-თი, არაფუნქციური
მოთხოვნები, პრიორიტეტები MoSCoW-ით, შეფასება Fibonacci-ის სკალაზე,
Definition of Done და MVP-ის სკოუპი.

| რა | სად |
|---|---|
| პროექტის აღწერა, stakeholder-ები, NFR, DoD, MVP | [BACKLOG.md](BACKLOG.md) |
| 16 story სრული acceptance criteria-თი | [stories/](stories/) და GitHub Issues |
| დაფა სვეტებით, MoSCoW-თი და ქულებით | [GitHub Projects](https://github.com/users/Yazo13/projects/2) |

- **16 user story**, თითოეულს 2-3 acceptance criterion Given/When/Then ფორმატში
- **6 არაფუნქციური მოთხოვნა**, თითოეული ციფრით გამოხატული
- **MVP = US-01 - US-08, ჯამში 45 ქულა**

---

## 2. არქიტექტურა

არქიტექტურული სტილი და მისი დასაბუთება, კომპონენტების დიაგრამა, design
pattern-ები ბექენდსა და ფრონტენდში, API, ბაზის სქემა, ტექნოლოგიური სტეკი და
რისკები.

[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

- **მოდულური მონოლითი + SPA კლიენტი**, სამი არგუმენტით
- **Filter / Decorator** ბექენდში, **Proxy + stale-while-revalidate** ფრონტენდში
- **PostgreSQL**, 32 ცხრილი, 9 global query filter მულტი-ტენანტობისთვის

დიაგრამები Mermaid-შია ჩაწერილი, ანუ პირდაპირ ამ გვერდზე იხატება.
