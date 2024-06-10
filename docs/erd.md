# Entity-Relationship Diagram
### Conceptual schema

```
+------------+                          +----------------+      +--------------+
| user       |-||--------------------<o-| post           |      | hashtag_list |
+------------+           1:M            +----------------+      +--------------+
  |   |   |                                |   |   |   |              |
  -   -   -                                -   -   -   -              -
  -   -   -                                -   -   -   -              -
  |   |   |                                |   |   |   |              |
  |   |   |                                |   |   |   |              | 1:M
  |   |   |          +----------+          |   |   |   |              |
  |   |   +-------<o-| like     |-o>-------+   |   |   |              ^
  |   |      1:M     +----------+     M:1      |   |   |              o
  |   |                                        |   |   |              |
  |   |              +----------+              |   |   |          +---------+
  |   +-----------<o-| favorite |-o>-----------+   |   +-------<o-| hashtag |
  |          1:M     +----------+     M:1          |      1:M     +---------+
  |                                                |
  |                  +----------+                  |
  +---------------<o-| comment  |-o>---------------+
             1:M     +----------+     M:1
```

### Cadinality and Modality

- A user can have zero or many posts
- A post belongs to one user

- A user can give zero or many likes
- A like belongs to one user

- A user can favorite zero or many posts
- A favorite belongs to one user

- A user can have zero or many comments
- A comment belongs to one user

---

- A post can have zero or many likes
- A like belongs to one user

- A post can have zero or many favorites
- A favorite belongs to one post

- A post can have zero or many comments
- A comment belongs to one post

---

- A hashtag_list can have zero or many hashtags
- A hashtag belongs to one hashtah_list

- A hashtag belongs to one post
- A post can belong zero or many hashtags

### Physical schema

```sql
| user                                             |
| ------------------------------------------------ |
| id          serial    PK                         |
| name        varchar      NOT NULL        CHECK   |
| email       varchar      NOT NULL UNIQUE CHECK   |
| username    varchar      NOT NULL UNIQUE CHECK   |
| created_on  timestamp    NOT NULL DEFAULT NOW    |
| last_login  timestamp    NOT NULL DEFAULT NOW    |
| profile_pic varchar                              | (add later)

| post                                             |
| ------------------------------------------------ |
| id          serial    PK                         |
| user_id     integer   FK NOT NULL                |
| created_on  timestamp    NOT NULL DEFAULT NOW()  |
| public      boolean      NOT NULL DEFAULT TRUE   |
| description varchar               DEFAULT ''     |
| photo       varchar                              | (add later)

| hashtag_list                                     |
| ------------------------------------------------ |
| id          serial    PK                         |
| title       varchar      NOT NULL                |

| hashtag                                          |
| ------------------------------------------------ |
| id          serial    PK                         |
| hashtag_id  integer   FK NOT NULL                |
| post_id     integer   FK NOT NULL                |

| like                                             |
| ------------------------------------------------ |
| id           serial    PK                        |
| post_id      integer   FK NOT NULL               |
| user_id      integer   FK NOT NULL               |
| liked_on     timestamp    NOT NULL DEFAULT NOW() |

| favorite                                         |
| ------------------------------------------------ |
| id           serial    PK                        |
| post_id      integer   FK NOT NULL               |
| user_id      integer   FK NOT NULL               |
| favorited_on timestamp    NOT NULL DEFAULT NOW() |

| comment                                          |
| ------------------------------------------------ |
| id           serial    PK                        |
| post_id      integer   FK NOT NULL               |
| user_id      integer   FK NOT NULL               |
| description  varchar      NOT NULL               |
| commented_on timestamp    NOT NULL DEFAULT NOW() |
```

