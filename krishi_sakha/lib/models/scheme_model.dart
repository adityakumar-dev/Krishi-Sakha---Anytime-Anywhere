// create table public.scheme_filters (
//   filter_type text not null,
//   filter_value text not null,
//   constraint scheme_filters_pkey primary key (filter_type, filter_value)
// ) TABLESPACE pg_default;

class SchemeModelFilter {
  final String filterType;
  final String filterValue;

  SchemeModelFilter({required this.filterType, required this.filterValue});
}
SchemeModelFilter fromJson(Map<String,dynamic> json){

  return SchemeModelFilter(
    filterType: json['filter_type'] as String,
    filterValue: json['filter_value'] as String,
  );
}
class SchemeModel {
  final String id;
  final String? highlight;
  final String? beneficiarystate;
  final String? schemeshorttitle;
  final String? level;
  final String? schemefor;
  final String? nodalministryname;
  final String? schemecategory;
  final String? schemename;
  final String? schemeclosedate;
  final double? priority;
  final String? slug;
  final String? briefdescription;
  final List<String>? tags;
  final DateTime? uploadDate;

  SchemeModel({
    required this.id,
    this.highlight,
    this.beneficiarystate,
    this.schemeshorttitle,
    this.level,
    this.schemefor,
    this.nodalministryname,
    this.schemecategory,
    this.schemename,
    this.schemeclosedate,
    this.priority,
    this.slug,
    this.briefdescription,
    this.tags,
    this.uploadDate,
  });

  factory SchemeModel.fromJson(Map<String, dynamic> json) {
    return SchemeModel(
      id: json['id'] as String,
      highlight: json['highlight'] as String?,
      beneficiarystate: json['beneficiarystate'] as String?,
      schemeshorttitle: json['schemeshorttitle'] as String?,
      level: json['level'] as String?,
      schemefor: json['schemefor'] as String?,
      nodalministryname: json['nodalministryname'] as String?,
      schemecategory: json['schemecategory'] as String?,
      schemename: json['schemename'] as String?,
      schemeclosedate: json['schemeclosedate'] as String?,
      priority: (json['priority'] as num?)?.toDouble(),
      slug: json['slug'] as String?,
      briefdescription: json['briefdescription'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      uploadDate: json['upload_date'] != null
          ? DateTime.parse(json['upload_date'])
          : null,
    );
  }  
}
