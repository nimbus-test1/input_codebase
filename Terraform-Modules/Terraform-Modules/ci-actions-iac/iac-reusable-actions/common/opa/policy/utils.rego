package tfanalysis

merge_object(a, b) = c {
	# iterate over the keys of a and b and creates a set of unique keys.
	keys := {k | _ = a[k]} | {k | _ = b[k]}

	# For each key k in the set keys, it assigns the corresponding value from either b or a using the pick function.
	c := {k: v | k := keys[_]; v := pick(k, b, a)}
}

exists(obj, k) {
	# check if the key k exists in the object obj.
	_ = obj[k]
}

# applies when the key k exist in obj1
pick(k, obj1, obj2) = v {
	v := obj1[k]
}

# applies when the key k does not exist in obj1
pick(k, obj1, obj2) = v {
	not exists(obj1, k)
	v := obj2[k]
}

keys(obj) = keys {
	keys := [k | _ = obj[k] ]
}

intersect(a, b) = c {
	c := [k | k := a[_]; exists(b, k)]
}
