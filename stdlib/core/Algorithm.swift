//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

func minElement<
     R : Sequence
       where R.GeneratorType.Element : Comparable>(range: R)
  -> R.GeneratorType.Element {
  var g = range.generate()
  var result = g.next()!  
  for e in GeneratorSequence(g) {
    if e < result { result = e }
  }
  return result
}

func maxElement<
     R : Sequence
       where R.GeneratorType.Element : Comparable>(range: R)
  -> R.GeneratorType.Element {
  var g = range.generate()
  var result = g.next()!
  for e in GeneratorSequence(g) {
    if e > result { result = e }
  }
  return result
}

// Returns the first index where value appears in domain or nil if
// domain doesn't contain the value. O(countElements(domain))
func find<
  C: Collection where C.GeneratorType.Element : Equatable
>(domain: C, value: C.GeneratorType.Element) -> C.IndexType? {
  for i in indices(domain) {
    if domain[i] == value {
      return i
    }
  }
  return nil
}

func insertionSort<
  C: MutableCollection where C.IndexType: BidirectionalIndex
>(
  inout elements: C,
  range: Range<C.IndexType>,
  inout less: (C.GeneratorType.Element, C.GeneratorType.Element)->Bool
) {
  if range {
    let start = range.startIndex

    // Keep track of the end of the initial sequence of sorted
    // elements.  
    var sortedEnd = start

    // One element is trivially already-sorted, thus pre-increment
    // Continue until the sorted elements cover the whole sequence
    while (++sortedEnd != range.endIndex) {
      // get the first unsorted element
      var x: C.GeneratorType.Element = elements[sortedEnd]

      // Look backwards for x's position in the sorted sequence,
      // moving elements forward to make room.
      var i = sortedEnd
      do {
        let predecessor: C.GeneratorType.Element = elements[i.pred()]
        
        // if x doesn't belong before y, we've found its position
        if !less(x, predecessor) {
          break
        }
        
        // Move y forward 
        elements[i] = predecessor
      }
      while --i != start
      
      if i != sortedEnd {
        // Plop x into position
        elements[i] = x
      }
    }
  }
}

/// Partition a non empty range into two partially sorted regions and return
/// the index of the pivot:
/// [start..idx), pivot ,[idx..end)
func partition<C: MutableCollection where C.IndexType: RandomAccessIndex>(
  inout elements: C,
  range: Range<C.IndexType>,
  inout less: (C.GeneratorType.Element, C.GeneratorType.Element)->Bool
) -> C.IndexType {

  _precondition(
    range.startIndex != range.endIndex, "Can't partition an empty range")

  // Variables i and j point to the next element to be visited.
  var i = range.startIndex
  var j = range.endIndex.pred()

  // The first element is the pivot.
  let pivot = elements[range.startIndex]
  i++

  // Continue to swap until all elements were visited and placed in one
  // of the partitions.
  while i.distanceTo(j) >= 0 {
    while less(elements[i], pivot) {
      i++
      if (i.distanceTo(j) < 0) { break }
    }
    while less(pivot, elements[j]) {
      j--
      // We don't need to check if j is greater than zero because we placed
      // our pivot at startIndex and comparing with pivot ends this loop.
    }
    if i.distanceTo(j) >= 0 {
      swap(&elements[i], &elements[j])
      i++
      j--
    }
  }

  // Swap the pivot in between the two partitions.
  swap(&elements[i.pred()], &elements[range.startIndex])
  return i.pred()
}


func quickSort<C: MutableCollection where C.IndexType: RandomAccessIndex>(
  inout elements: C,
  range: Range<C.IndexType>,
  less: (C.GeneratorType.Element, C.GeneratorType.Element)->Bool
) {
  var comp = less
  _quickSort(&elements, range, &comp)
}

func _quickSort<C: MutableCollection where C.IndexType: RandomAccessIndex>(
  inout elements: C,
  range: Range<C.IndexType>,
  inout less: (C.GeneratorType.Element, C.GeneratorType.Element)->Bool
) {

  // Insertion sort is better at handling smaller regions.
  let cnt = count(range)
  if cnt < 20 {
    insertionSort(&elements, range, &less)
    return
  }

   // Partition and sort.
  let part_idx : C.IndexType = partition(&elements, range, &less)
  _quickSort(&elements, range.startIndex..<part_idx, &less);
  _quickSort(&elements, (part_idx.succ())..<range.endIndex, &less);
}

struct Less<T: Comparable> {
  static func compare(x: T, _ y: T) -> Bool {
    return x < y
  }
}

func sort<
  C: MutableCollection where C.IndexType: RandomAccessIndex
>(
  inout collection: C,
  pred: (C.GeneratorType.Element, C.GeneratorType.Element) -> Bool
) {
  quickSort(&collection, indices(collection), pred)
}

func sort<
  C: MutableCollection 
    where C.IndexType: RandomAccessIndex, C.GeneratorType.Element: Comparable
>(
  inout collection: C
) {
  quickSort(&collection, indices(collection))
}

func sort<T>(inout array: T[], pred: (T, T) -> Bool) {
  return array.withMutableStorage {
    a in sort(&a, pred)
    return
  }
}

/// The functions below are a copy of the functions above except that
/// they don't accept a predicate and they are hardcoded to use the less-than
/// comparator.
func sort<T : Comparable>(inout array: T[]) {
  return array.withMutableStorage {
    a in sort(&a)
    return
  }
}

func sorted<
  C: MutableCollection where C.IndexType: RandomAccessIndex
>(
  source: C,
  pred: (C.GeneratorType.Element, C.GeneratorType.Element) -> Bool
) -> C {
  var result = source
  sort(&result, pred)
  return result
}

func sorted<
  C: MutableCollection 
    where C.GeneratorType.Element: Comparable, C.IndexType: RandomAccessIndex
>(source: C) -> C {
  var result = source
  sort(&result)
  return result
}

func sorted<
  S: Sequence
>(
  source: S,
  pred: (S.GeneratorType.Element, S.GeneratorType.Element) -> Bool
) -> S.GeneratorType.Element[] {
  var result = Array(source)
  sort(&result, pred)
  return result
}

func sorted<
  S: Sequence 
    where S.GeneratorType.Element: Comparable
>(
  source: S
) -> S.GeneratorType.Element[] {
  var result = Array(source)
  sort(&result)
  return result
}

func insertionSort<
  C: MutableCollection where C.IndexType: RandomAccessIndex,
  C.GeneratorType.Element: Comparable>(
  inout elements: C,
  range: Range<C.IndexType>) {

  if range {
    let start = range.startIndex

    // Keep track of the end of the initial sequence of sorted
    // elements.
    var sortedEnd = start

    // One element is trivially already-sorted, thus pre-increment
    // Continue until the sorted elements cover the whole sequence
    while (++sortedEnd != range.endIndex) {
      // get the first unsorted element
      var x: C.GeneratorType.Element = elements[sortedEnd]

      // Look backwards for x's position in the sorted sequence,
      // moving elements forward to make room.
      var i = sortedEnd
      do {
        let predecessor: C.GeneratorType.Element = elements[i.pred()]

        // if x doesn't belong before y, we've found its position
        if !Less.compare(x, predecessor) {
          break
        }

        // Move y forward
        elements[i] = predecessor
      }
      while --i != start

      if i != sortedEnd {
        // Plop x into position
        elements[i] = x
      }
    }
  }
}

/// Partition a non empty range into two partially sorted regions and return
/// the index of the pivot:
/// [start..idx), pivot ,[idx..end)
func partition<
  C: MutableCollection where C.GeneratorType.Element: Comparable
, C.IndexType: RandomAccessIndex
>(
  inout elements: C,
  range: Range<C.IndexType>) -> C.IndexType {

  // Variables i and j point to the next element to be visited.
  var i = range.startIndex
  var j = range.endIndex.pred()

  // The first element is the pivot.
  let pivot = elements[range.startIndex]
  i++

  // Continue to swap until all elements were visited and placed in one
  // of the partitions.
  while i.distanceTo(j) >= 0 {
    while Less.compare(elements[i], pivot) {
      i++
      if (i.distanceTo(j) < 0) { break }
    }
    while Less.compare(pivot, elements[j]) {
      // We don't need to check if j is greater than zero because we placed
      // our pivot at startIndex and comparing with pivot ends this loop.
      j--
    }
    if i.distanceTo(j) >= 0 {
      swap(&elements[i], &elements[j])
      i++
      j--
    }
  }

  // Swap the pivot in between the two partitions.
  swap(&elements[i.pred()], &elements[range.startIndex])
  return i.pred()
}

func quickSort<
  C: MutableCollection
    where C.GeneratorType.Element: Comparable, C.IndexType: RandomAccessIndex
>(
  inout elements: C,
  range: Range<C.IndexType>) {
  _quickSort(&elements, range)
}

func _quickSort<
  C: MutableCollection
    where C.GeneratorType.Element: Comparable, C.IndexType: RandomAccessIndex
>(
  inout elements: C, range: Range<C.IndexType>
) {
  // Insertion sort is better at handling smaller regions.
  let cnt = count(range)
  if cnt < 20 {
    insertionSort(&elements, range)
    return
  }
   // Partition and sort.
  let part_idx : C.IndexType = partition(&elements, range)
  _quickSort(&elements, range.startIndex..<part_idx);
  _quickSort(&elements, (part_idx.succ())..<range.endIndex);
}
//// End of non-predicate sort functions.


func swap<T>(inout a : T, inout b : T) {
  // Semantically equivalent to (a, b) = (b, a).
  // Microoptimized to avoid retain/release traffic.
  let p1 = Builtin.addressof(&a)
  let p2 = Builtin.addressof(&b)
  
  // Take from P1.
  let tmp : T = Builtin.take(p1)
  // Transfer P2 into P1.
  Builtin.initialize(Builtin.take(p2) as T, p1)
  // Initialize P2.
  Builtin.initialize(tmp, p2)
}


func min<T : Comparable>(x: T, y: T) -> T {
  var r = x
  if y < x {
    r = y
  }
  return r
}

func min<T : Comparable>(x: T, y: T, z: T, rest: T...) -> T {
  var r = x
  if y < x {
    r = y
  }
  if z < r {
    r = z
  }
  for t in rest {
    if t < r {
      r = t
    }
  }
  return r
}

func max<T : Comparable>(x: T, y: T) -> T {
  var r = y
  if y < x {
    r = x
  }
  return r
}

func max<T : Comparable>(x: T, y: T, z: T, rest: T...) -> T {
  var r = y
  if y < x {
    r = x
  }
  if r < z {
    r = z
  }
  for t in rest {
    if t >= r {
      r = t
    }
  }
  return r
}

func split<Seq: Sliceable, R:LogicValue>(
  seq: Seq, 
  isSeparator: (Seq.GeneratorType.Element)->R, 
  maxSplit: Int = Int.max,
  allowEmptySlices: Bool = false
  ) -> Seq.SliceType[] {

  var result = Array<Seq.SliceType>()

  // FIXME: could be simplified pending <rdar://problem/15032945>
  // (ternary operator not resolving some/none)
  var startIndex: Optional<Seq.IndexType>
     = allowEmptySlices ? .Some(seq.startIndex) : .None
  var splits = 0

  for j in indices(seq) {
    if isSeparator(seq[j]) {
      if startIndex {
        var i = startIndex!
        result.append(seq[i..<j])
        startIndex = .Some(j.succ())
        if ++splits >= maxSplit {
          break
        }
        if !allowEmptySlices {
          startIndex = .None
        }
      }
    }
    else {
      if !startIndex {
        startIndex = .Some(j)
      }
    }
  }

  switch startIndex {
  case .Some(var i):
    result.append(seq[i..<seq.endIndex])
  default:
    ()
  }
  return result
}

/// Return true iff the elements of `e1` are equal to the initial
/// elements of `e2`.
func startsWith<
  S0: Sequence, S1: Sequence
  where 
    S0.GeneratorType.Element == S1.GeneratorType.Element, 
    S0.GeneratorType.Element : Equatable
>(s0: S0, s1: S1) -> Bool
{
  var g1 = s1.generate()

  for e0 in s0 {
    var e1 = g1.next()
    if !e1 { return true }
    if e0 != e1! {
      return false
    }
  }
  return g1.next() ? false : true
}

struct EnumerateGenerator<Base: Generator> : Generator, Sequence {
  typealias Element = (index: Int, element: Base.Element)
  var base: Base
  var count: Int

  init(_ base: Base) {
    self.base = base
    count = 0
  }

  mutating func next() -> Element? {
    var b = base.next()
    if !b { return .None }
    return .Some((index: count++, element: b!))
  }

  // Every Generator is also a single-pass Sequence
  typealias GeneratorType = EnumerateGenerator<Base>
  func generate() -> GeneratorType {
    return self
  }
}

func enumerate<Seq : Sequence>(
  seq: Seq
) -> EnumerateGenerator<Seq.GeneratorType> {
  return EnumerateGenerator(seq.generate())
}


/// Return true iff `a1` and `a2` contain the same elements.
func equal<
    S1 : Sequence, S2 : Sequence
  where
    S1.GeneratorType.Element == S2.GeneratorType.Element,
    S1.GeneratorType.Element : Equatable
>(a1: S1, a2: S2) -> Bool
{
  var g1 = a1.generate()
  var g2 = a2.generate()
  while true {
    var e1 = g1.next()
    var e2 = g2.next()
    if e1 && e2 {
      if e1! != e2! {
        return false
      }
    }
    else {
      return !e1 == !e2
    }
  }
}

/// Return true iff `a1` and `a2` contain the same elements, using
/// `pred` as equality `==` comparison.
func equal<
    S1 : Sequence, S2 : Sequence
  where
    S1.GeneratorType.Element == S2.GeneratorType.Element
>(a1: S1, a2: S2,
  pred: (S1.GeneratorType.Element, S1.GeneratorType.Element) -> Bool) -> Bool
{
  var g1 = a1.generate()
  var g2 = a2.generate()
  while true {
    var e1 = g1.next()
    var e2 = g2.next()
    if e1 && e2 {
      if !pred(e1!, e2!) {
        return false
      }
    }
    else {
      return !e1 == !e2
    }
  }
}

/// Return true iff a1 precedes a2 in a lexicographical ("dictionary")
/// ordering, using "<" as the comparison between elements.
func lexicographicalCompare<
    S1 : Sequence, S2 : Sequence
  where 
    S1.GeneratorType.Element == S2.GeneratorType.Element,
    S1.GeneratorType.Element : Comparable>(
  a1: S1, a2: S2) -> Bool {
  var g1 = a1.generate()
  var g2 = a2.generate()
  while true {
    var e1_ = g1.next()
    var e2_ = g2.next()
    if let e1 = e1_ {
      if let e2 = e2_ {
        if e1 < e2 {
          return true
        }
        if e2 < e1 {
          return false
        }
        continue // equivalent
      }
      return false
    }
    return e2_.getLogicValue()
  }
}

/// Return true iff `a1` precedes `a2` in a lexicographical ("dictionary")
/// ordering, using `less` as the comparison between elements.
func lexicographicalCompare<
    S1 : Sequence, S2 : Sequence
  where 
    S1.GeneratorType.Element == S2.GeneratorType.Element
>(
  a1: S1, a2: S2,
  less: (S1.GeneratorType.Element,S1.GeneratorType.Element)->Bool
) -> Bool {
  var g1 = a1.generate()
  var g2 = a2.generate()
  while true {
    var e1_ = g1.next()
    var e2_ = g2.next()
    if let e1 = e1_ {
      if let e2 = e2_ {
        if less(e1, e2) {
          return true
        }
        if less(e2, e1) {
          return false
        }
        continue // equivalent
      }
      return false
    }
    return e2_.getLogicValue()
  }
}

/// Return `true` iff an element in `seq` satisfies `predicate`.
func contains<
  S: Sequence, L: LogicValue
>(seq: S, predicate: (S.GeneratorType.Element)->L) -> Bool {
  for a in seq {
    if predicate(a) {
      return true
    }
  }
  return false
}

/// Return `true` iff `x` is in `seq`.
func contains<
  S: Sequence where S.GeneratorType.Element: Equatable
>(seq: S, x: S.GeneratorType.Element) -> Bool {
  return contains(seq, { $0 == x })
}

func reduce<S: Sequence, U>(
  sequence: S, initial: U, combine: (U, S.GeneratorType.Element)->U
) -> U {
  var result = initial
  for element in sequence {
    result = combine(result, element)
  }
  return result
}
