class Sort {
  final bool? empty;
  final bool? sorted;
  final bool? unsorted;

  Sort({required this.empty, required this.sorted, required this.unsorted});

  factory Sort.fromJson(Map<String, dynamic> json) => Sort(
        empty: json['empty'],
        sorted: json['sorted'],
        unsorted: json['unsorted'],
      );
  Map<String, dynamic> toJson() => {
        'empty': empty,
        'sorted': sorted,
        'unsorted': unsorted,
      };
}
