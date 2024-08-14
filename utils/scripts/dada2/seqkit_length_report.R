#!/usr/bin/env Rscript	
suppressMessages(library(ggplot2))
suppressMessages(library(limma))
suppressMessages(library(dplyr))
suppressMessages(library(plotly))
suppressMessages(library(dplyr))
suppressMessages(library(htmlwidgets))



args = commandArgs(trailingOnly=TRUE)

forward_read_suffix <- args[3]
reverse_read_suffix <- args[4]
primer_removal <- args[5]


# Convert the value to logical if necessary
if (is.character(primer_removal)) {
  if (tolower(primer_removal) == "true") {
    primer_removal <- TRUE
  } else if (tolower(primer_removal) == "false") {
    primer_removal <- FALSE
  }
}



##reading files in and save them as objects
object_names <- list.files(args[1], pattern = paste0(forward_read_suffix,"|",reverse_read_suffix),full.names = T)


for (i in 1:length(object_names)) {
  # Read in the object
  my_data <- read.table(object_names[i],header = F)
  # Save the updated object
  assign(x=gsub(".txt","",basename(object_names[i])),value = my_data)
  
}


## fixing raw files
raw_objects <- ls(pattern = "raw")

for (i in raw_objects){
  # Read in the object
  my_data <- get(i)
  if (nrow(my_data) == 1){ #this for times that primers are already removed from raw reads and they are not the same length anymore
    my_data <- data.frame(
      V1 = seq_along(1:my_data$V1),
      V2 = c(rep(x = 0, times = my_data$V1-1), rep(my_data$V2, times = 1))) # Add missing closing parentheses
    #Save the updated object
    assign(i, value = my_data)
  }
}



object_names <- ls(pattern = paste0(forward_read_suffix,"|",reverse_read_suffix))


#### Loop over each file and change the column names and save them as a new object each
for (i in object_names) {
  # Read in the object
  my_data <- get(i)
  
  # Print the current column names
  #print(colnames(my_data))
  
  # Change the column names
  colnames(my_data) <- c("read_length", "num_reads")
  
  # Print the new column names
  #print(colnames(my_data))
  
  # Save the updated object
  assign(i,value = my_data)
}



#add two columns of readtype and filetype to all object files based on a name

# Conditional logic
if (primer_removal == TRUE) {
  names <- c("raw", "dada2", "primerRMV", "cutadapt")
} else {
  names <- c("raw", "dada2", "cutadapt")
}


# loop over the selected objects and add columns to them
for (i in names){
  objs <- ls(pattern = i)
  for (j in objs){
    x <- get(j)
    x <- cbind(x, filetype = i)
    colnames(x)
    assign(j, x)
  }
}


reads <- c(forward_read_suffix,reverse_read_suffix)


# loop over the selected objects and add columns to them
for (i in reads){
  objs <- ls(pattern = i)
  for (j in objs){
    x <- get(j)
    x <- cbind(x, readtype = i)
    colnames(x)
    assign(j, x)
  }
}



names<-unique(sapply(strsplit(object_names,split=paste0(forward_read_suffix,"|",reverse_read_suffix)),`[`,1))

# Loop through the list of object names and combine them using rbind
for (i in names){
  obj_list=ls(pattern = i)
  combined_data <- data.frame() # Create an empty data frame to store the combined data
  for (j in obj_list) {
    obj <- get(j)
    if (is.data.frame(obj)) {
      combined_data <- rbind(combined_data, obj)
      assign(x = paste0("combined_",i), combined_data)
    }
  }
}

print(dim(combined_data))

rm(combined_data)

# Loop through each file and make column filetype a factor and add a column as sample_name
for (file in ls(pattern = "combined_")) {
  # Read in the file
  data <- get(file)
  
  if (primer_removal == TRUE) {
    # Convert the desired column to a factor
    data$filetype <- factor(data$filetype,levels = c("raw","cutadapt","primerRMV","dada2"))
  } else {
    # Convert the desired column to a factor
    data$filetype <- factor(data$filetype,levels = c("raw","cutadapt","dada2"))
  }
  
  # Add a new column
  name <- strsplit2(file,split = "combined_")[2]
  data$sample_name <- name
  
  # Save the modified file back to disk
  assign(value = data, x = file)
}



final_data <- data.frame() # Create an empty data frame to store the combined data


files=ls(pattern = "combined_")
print(files)

# Loop through the list of combined sample object names and combine them using rbind
for (i in files){
  obj <- get(i)
  if (is.data.frame(obj)) {
    final_data <- rbind(final_data, obj)
  }
}


final_data <- final_data %>%
  mutate(readtype = gsub(forward_read_suffix, "R1", readtype),
         readtype = gsub(reverse_read_suffix, "R2", readtype))



p <- ggplot(final_data %>% filter(num_reads > 0), aes(x = read_length, y = num_reads, fill = sample_name)) +
  geom_col(width = 1) +
  theme_bw() +
  labs(title = "All the reads in all samples length distribution") +
  xlab("Length (bp)") +
  ylab("Reads") +
  theme(legend.position = "right")





if (primer_removal == TRUE) {
  # Convert to plotly and enable zooming
  plotly_p <- p +
    facet_wrap(readtype ~ filetype, ncol = 4, nrow = 2)
  plotly_p <- plotly_p %>% plotly::ggplotly() %>%  
    layout(xaxis = list(rangeslider = list(visible = TRUE), rangemode = "normal"),
           xaxis2 = list(rangeslider = list(visible = TRUE), rangemode = "normal"),
           xaxis3 = list(rangeslider = list(visible = TRUE), rangemode = "normal"),
           xaxis4 = list(rangeslider = list(visible = TRUE), rangemode = "normal"),
           yaxis = list(fixedrange = FALSE))
  } else {
  # Convert to plotly and enable zooming
  plotly_p <- p +
    facet_wrap(readtype ~ filetype, ncol = 3, nrow = 2) 
  plotly_p <- plotly_p %>% plotly::ggplotly() %>%
    layout(xaxis = list(rangeslider = list(visible = TRUE), rangemode = "normal"),
           xaxis2 = list(rangeslider = list(visible = TRUE), rangemode = "normal"),
           xaxis3 = list(rangeslider = list(visible = TRUE), rangemode = "normal"),
           yaxis = list(fixedrange = FALSE))
  }



# Show the plot
plotly_p


htmlwidgets::saveWidget(plotly_p, args[2])
