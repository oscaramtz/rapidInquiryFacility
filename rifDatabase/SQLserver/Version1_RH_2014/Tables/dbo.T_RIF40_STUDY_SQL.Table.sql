USE [RIF40]
GO
/****** Object:  Table [dbo].[T_RIF40_STUDY_SQL]    Script Date: 19/09/2014 12:07:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[T_RIF40_STUDY_SQL](
	[USERNAME] [varchar](90) NOT NULL,
	[STUDY_ID] [numeric](8, 0) NOT NULL,
	[STATEMENT_TYPE] [varchar](30) NOT NULL,
	[STATEMENT_NUMBER] [numeric](6, 0) NOT NULL,
	[SQL_TEXT] [varchar](4000) NOT NULL,
	[LINE_NUMBER] [numeric](6, 0) NOT NULL,
	[STATUS] [varchar](1) NULL,
 CONSTRAINT [T_RIF40_STUDY_SQL_PK] PRIMARY KEY CLUSTERED 
(
	[STUDY_ID] ASC,
	[STATEMENT_NUMBER] ASC,
	[LINE_NUMBER] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[T_RIF40_STUDY_SQL] ADD  DEFAULT (user_name()) FOR [USERNAME]
GO
ALTER TABLE [dbo].[T_RIF40_STUDY_SQL]  WITH NOCHECK ADD  CONSTRAINT [T_RIF40_STUDY_SQL_SID_LINE_FK] FOREIGN KEY([STUDY_ID], [STATEMENT_NUMBER])
REFERENCES [dbo].[T_RIF40_STUDY_SQL_LOG] ([STUDY_ID], [STATEMENT_NUMBER])
GO
ALTER TABLE [dbo].[T_RIF40_STUDY_SQL] CHECK CONSTRAINT [T_RIF40_STUDY_SQL_SID_LINE_FK]
GO
ALTER TABLE [dbo].[T_RIF40_STUDY_SQL]  WITH CHECK ADD  CONSTRAINT [STATEMENT_TYPE_CK2] CHECK  (([STATEMENT_TYPE]='DENOMINATOR_CHECK' OR [STATEMENT_TYPE]='NUMERATOR_CHECK' OR [STATEMENT_TYPE]='POST_INSERT' OR [STATEMENT_TYPE]='INSERT' OR [STATEMENT_TYPE]='CREATE'))
GO
ALTER TABLE [dbo].[T_RIF40_STUDY_SQL] CHECK CONSTRAINT [STATEMENT_TYPE_CK2]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL.USERNAME' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL', @level2type=N'COLUMN',@level2name=N'USERNAME'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL.STUDY_ID' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL', @level2type=N'COLUMN',@level2name=N'STUDY_ID'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL.STATEMENT_TYPE' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL', @level2type=N'COLUMN',@level2name=N'STATEMENT_TYPE'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL.STATEMENT_NUMBER' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL', @level2type=N'COLUMN',@level2name=N'STATEMENT_NUMBER'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL.SQL_TEXT' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL', @level2type=N'COLUMN',@level2name=N'SQL_TEXT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL.LINE_NUMBER' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL', @level2type=N'COLUMN',@level2name=N'LINE_NUMBER'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL.STATUS' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL', @level2type=N'COLUMN',@level2name=N'STATUS'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL.T_RIF40_STUDY_SQL_PK' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL', @level2type=N'CONSTRAINT',@level2name=N'T_RIF40_STUDY_SQL_PK'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_SSMA_SOURCE', @value=N'RIF40.T_RIF40_STUDY_SQL.STATEMENT_TYPE_CK2' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'T_RIF40_STUDY_SQL', @level2type=N'CONSTRAINT',@level2name=N'STATEMENT_TYPE_CK2'
GO
