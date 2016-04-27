# For configuring target applications that use MemClient annotations
function (use_DrStackvis_annotations target target_srcs)
  set(stackvis_annotation_dir "${DrStackvis_cwd}/../annotations")
  set(stackvis_annotation_srcs "${stackvis_annotation_dir}/memclient_annotations.c")
  configure_DynamoRIO_annotation_sources("${stackvis_annotation_srcs}")
  set(${target_srcs} ${${target_srcs}} ${stackvis_annotation_srcs} PARENT_SCOPE)
endfunction (use_DrStackvis_annotations target target_srcs)
