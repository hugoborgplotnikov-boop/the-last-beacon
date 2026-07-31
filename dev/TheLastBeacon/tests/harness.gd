extends RefCounted
## Tiny assertion helper shared by the headless test scripts.
## Each test script creates one Harness, calls check() during the simulated
## playthrough, then calls summary() and exits 0/1 accordingly.

var name: String
var failures: Array[String] = []


func _init(test_name: String) -> void:
	name = test_name


func check(condition: bool, label: String) -> void:
	if condition:
		print("  ok: ", label)
	else:
		failures.append(label)
		printerr("  FAIL: ", label)


func summary() -> bool:
	var passed := failures.is_empty()
	print("=== TEST ", name, ": ", "PASS" if passed else "FAIL", " ===")
	if not passed:
		printerr("Failed checks: ", ", ".join(failures))
	return passed
