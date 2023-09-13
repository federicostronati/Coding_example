#Setting working directory
setwd("C:/Users/fedes/Desktop/Project STATS/ChicagoHouse")

#Importing the dataset ChicagoHouse
data1 <- read.table("ChicagoHouse.txt", header=TRUE)
data <- data1[,1:9]
#Basic look at the data
summary(data)
attach(data)

#Var-Covar matrix, correlation matrix
covar_matrix <- cov(data)
covar_matrix
corr_matrix <- cor(data)
corr_matrix

#Creating histograms to look at the distribution 
#of the not scaled variables
colindex <- c(1:9)
columns <- colnames(data)
for (i in colindex){
  variable <- (data[,i])
  column_name <- columns[i]
  hist(variable, main = column_name)
}

#Creating some scatterplots for the most important variables

install.packages("plotrix")
library(plotrix)

library(ggplot2)


ggplot(data=data, aes(price, crime)) +
  geom_point() +
  geom_smooth(method="lm", se=FALSE)
draw.ellipse(x= c(10000), y= c(75), c(1000), c(3), border = 'black', lwd = 2)

ggplot(data=data, aes(price, rooms)) +
  geom_point() +
  geom_smooth(method="lm", se=FALSE)

ggplot(data=data, aes(price, lowstat)) +
  geom_point() +
  geom_smooth(method="lm", se=FALSE)

ggplot(data=data, aes(price, proptax)) +
  geom_point() +
  geom_smooth(method="lm", se=FALSE)

ggplot(data=data, aes(price, nox)) +
  geom_point() +
  geom_smooth(method="lm", se=FALSE)

#So we standardize the data using the scale function, as price has a different scale
library(dplyr)
data_s <- scale(data)

scovar_matrix <- cov(data_s)
scovar_matrix
#The scaled covariance matrix is the same 
#as the unscaled correlation matrix!


#############################################
#PCA (on scaled data)
pca <- princomp(as.data.frame(data_s), cor=TRUE)  
pca 
summary(pca)
screeplot(pca, npcs=8, type="l", ylim=c(0,5), main="")
#Looking at the screeplot, we see how we might want to keep 
#one or two components

#storing the unscaled component loadings
loadings <- pca$loadings 
#Eigenvalues of the scaled covariance matrix 
eigenval<-(pca$sdev)^2

#Cumulative variance plot
explained_variance <- eigenval/sum(eigenval)
plot(cumsum(explained_variance[1:9]), xlab = "Principal Component",
     ylab = "Proportion of Variance Explained",
     xlim=c(0,9),ylim = c(0, 1), type = "b")
abline(h=0.7, col="red")

#We now compute the scaled component loadings
D <- matrix(0, dim(loadings)[1], dim(loadings)[2])
diag(D)<-eigenval
D
comp_loadings <- loadings %*% sqrt(D) #scaled loadings (i.e. component loadings)

#If we keep  eigenval>1, we keep the first 2
#If we keep  eigenval>0.7, we keep the first 3 instead
eigenval
#Also from the screeplot, the elbow is at 2

#Looking at the first 3
loadings[,1:3]
comp_loadings[,1:3]
#Looking at the first 2
loadings[,1:2]
comp_loadings[,1:2] #These are the ones we will interpret
#Preliminary considerations:
#The first component clearly measures some sort of 
#wealth/poverty/social status/stratification/whatever 
#essentially dividing between better off neighbourhoods 
#and more problematic ones 

#Computing the scores of the pca
#We want to rescale them so that they have unit variance
stand.coeff<-comp_loadings%*% diag(1/eigenval)
score <- as.matrix(data_s)%*%stand.coeff
#The var of these is 1: round(var(score),3)

#Alternatively, if we keep only 2 components, we plot them manually
plot(score[,1], score[,2], xlab="PC1 scores", ylab="PC2 scores")
abline(h=0, v=0, lwidth=0.5, col="lightgray")
#plot(-score[,1], -score[,2], xlab="PC1 scores", ylab="PC2 scores")


######################################
#CLUSTER ANALYSIS
distance <- dist(data_s) #euclidean distance between observations
dist <- as.matrix(distance)

#Hierarchical Clustering Methods
#Single linkage method 
hc.s <- hclust(distance, method='single')
plot(hc.s, labels=FALSE, xlab="Distance") 

#Complete linkage method 
hc.c<-hclust(distance) 
plot(hc.c, labels = FALSE, xlab="Distance")

#Ward Method
hc.w<-hclust(distance, method='ward.D2')
plot(hc.w, labels = FALSE)

#Centroid method
hc.ce<-hclust(distance, method='centroid')
plot(hc.ce, labels = FALSE)

#We immediately discard the single linkage and centroid methods
#When it comes to complete linkage, we discover a problem
#For any number of clusters above 2, there is a problematic cluster
#that encompasses only 3 observations
#We theorized these might in fact be the three outliers that we saw
#in the beginning in the price/crime scatterplot
hc.c<-hclust(distance) 
plot(hc.c, labels = FALSE, xlab="Distance")

plot(price, crime, labels=TRUE)
draw.ellipse(x= c(7600), y= c(76), c(3800), c(10), angle=0.18, border='red', lwd = 1.5, deg=TRUE)
#text(price, crime, labels=rownames(data), cex=0.9, font=2)

#Indeed, those three correspond to observations 381, 406, and 419 
#Out of curiosity, we decided to check what the complete linkage method yields 
#if we decide to drop these three observations
data2 <- data[-c(381, 406, 419), ]
data2_s <- data_s[-c(381, 406, 419), ]
distance2 <- dist(data2_s)

hc.c.2<-hclust(distance2) 
plot(hc.c.2, labels = FALSE, xlab="Distance")
#The dendogram looks significntly better, but we still decided to continue our
#analysis using the Ward clustering method

#To decide the optimal number of clusters to create with the Ward method,
#we compute a  silhouette index
library(NbClust)
NbClust(data=data_s,diss=NULL,distance="euclidean",min.nc=2,max.nc=6,method="ward.D2",index="silhouette")
#The optimal number of clusters is 2

#We cut the dendograms to obtain 2 and 3 clusters
member.w.2 <- cutree(hc.w, k=2)
member.w.3 <- cutree(hc.w, k=3)

#Comparing the observations of the 3 clusters between different methods
tapply(rownames(as.data.frame(data_s)), member.w.2, c)
tapply(rownames(as.data.frame(data_s)), member.w.3, c)
#The 3 clusters are actually more balanced than the two

#In order to interpret the clusters, in the following Tables we
#report the means of the actual variables respectively within each cluster.
aggregate(data,list(member.w.2),mean)

aggregate(data,list(member.w.3),mean)#means of the actual variables within each cluster


#Non-hierarchical clustering
set.seed(69)
#We also make a scree plot (using the k-means method)
#Which confirms that indeed for our data it is reasonable to
#create 2 clusters
wss<-(nrow(data_s)-1)*sum(apply(data_s,2,var))
for (i in 2:20)wss[i]<-sum(kmeans(data_s,centers=i)$withinss)
plot(1:20,wss,type="b",xlab="Number of Clusters",ylab="Within group SS")

#Finally, we proceed with the k-means method of clustering
kc.2<-kmeans(data_s,2)
kc.2
#This time we necessarily have the means of the standardized variables,
#rather tahtn the level means
#Interpretation works all, the same, and for comparison, we report the 
#equivalent standardized means form the ward clusters
kc.2$centers
aggregate(data_s,list(member.w.2),mean)