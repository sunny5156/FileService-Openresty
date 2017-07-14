/*
SQLyog Ultimate v12.4.1 (64 bit)
MySQL - 5.6.36 : Database - db_filesystem
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`db_filesystem` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `db_filesystem`;

/*Table structure for table `fs_attachment` */

DROP TABLE IF EXISTS `fs_attachment`;

CREATE TABLE `fs_attachment` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(60) DEFAULT '' COMMENT '类型',
  `name` varchar(150) DEFAULT '' COMMENT '文件名称',
  `size` int(11) DEFAULT '0' COMMENT '大小',
  `savepath` varchar(255) DEFAULT '' COMMENT '文件路径',
  `savename` varchar(255) DEFAULT '' COMMENT '文件保存名',
  `ext` char(10) DEFAULT NULL COMMENT '文件类型',
  `hash` text NOT NULL COMMENT '图像hash',
  `create_time` int(11) DEFAULT '0' COMMENT '创建时间',
  `update_time` int(11) DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `url` (`savepath`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

/*Data for the table `fs_attachment` */

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
