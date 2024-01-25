Utils, mostly macros for typical use-cases


#### debug.jinja
Helper to dump context passed as arg
e.g.
```
{% from "kubernetes/master/map.jinja" import kubernetes with context %}
{% from "_common/debug.jinja" import dump %}


{{ dump(kubernetes) }}
```