USE [RIF40]
GO
/****** Object:  Table [dbo].[RIF40_AGE_GROUP_NAMES]    Script Date: 19/09/2014 12:07:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RIF40_AGE_GROUP_NAMES](
	[AGE_GROUP_ID] [numeric](3, 0) NOT NULL,
	[AGE_GROUP_NAME] [varchar](50) NOT NULL,
 CONSTRAINT [RIF40_AGE_GROUP_NAMES_PK] PRIMARY KEY CLUSTERED 
(
	[AGE_GROUP_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.RIF40_AGE_GROUP_NAMES.AGE_GROUP_ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RIF40_AGE_GROUP_NAMES', @level2type=N'COLUMN',@level2name=N'AGE_GROUP_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.RIF40_AGE_GROUP_NAMES.AGE_GROUP_NAME' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RIF40_AGE_GROUP_NAMES', @level2type=N'COLUMN',@level2name=N'AGE_GROUP_NAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.RIF40_AGE_GROUP_NAMES' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RIF40_AGE_GROUP_NAMES'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.RIF40_AGE_GROUP_NAMES.RIF40_AGE_GROUP_NAMES_PK' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RIF40_AGE_GROUP_NAMES', @level2type=N'CONSTRAINT',@level2name=N'RIF40_AGE_GROUP_NAMES_PK'
GO
