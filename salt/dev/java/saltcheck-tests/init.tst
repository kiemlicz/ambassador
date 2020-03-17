{% from "java/map.jinja" import java_type,openjdk_java with context %}

verify_java_pkg:
  module_and_function: pkg.upgrade_available
  args:
    - {{ openjdk_java.pkg_name }}
  assertion: assertFalse

verify_java_home:
  module_and_function: file.search
  args:
    - {{ openjdk_java.exports_file }}
    - {{ openjdk_java.environ_variable }}
  assertion: assertTrue
