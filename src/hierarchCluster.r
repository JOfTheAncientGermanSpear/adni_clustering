run <- function(write_to_file=TRUE){
  pat_z <- read.csv("../data/patients_z.csv")
  pat_z_data = as.matrix(pat_z[4:93])

  d <- dist(pat_z_data)
  hc <- hclust(d, method="ward.D")
  group <- cutree(hc, k=4)

  RID <- pat_z$RID
  ret <- data.frame(RID, group)
  
  if(write_to_file) {
    dest_f <- "../data/output/ward_cluster_result.csv"
    write.csv(ret, file=dest_f, row.names=FALSE)
  }
  
  ret
}
