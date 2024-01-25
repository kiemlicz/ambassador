# somewhat more readable version os this state could just do:
#include:
#  - base: users
#  - users.projects
#
# in other environments (saltenv=dev) however currently this yields:
# "Detected conflicting IDs, SLS IDs need to be globally unique."
# "The conflicting ID is 'os-notification' and is found in SLS 'dev:os' and SLS 'base:os'"
# etc for all included states
# Whole file could be overriden in other envs but that would lead to duplication
# that is the reason why there is macro that inspects saltenv and generates proper users state
{% from "users/users.jinja" import users_state with context %}

{{ users_state(saltenv) }}
