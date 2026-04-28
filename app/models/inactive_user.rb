# typed: false

module InactiveUser
  def self.inactive_user
    @inactive_user ||= User.find_by!(username: "inactive-user")
  end

  def self.disown! comment_or_story
    author = comment_or_story.user
    comment_or_story.update_column(:user_id, inactive_user.id)
    refresh_counts! author
  end

  def self.disown_all_by_author! author
    # leave attribution on deleted stuff, which is generally very relevant to mods
    # when looking back at returning users
    author.stories.not_deleted(nil).update_all(user_id: inactive_user.id)
    # leave attribution on comments made with a modlog hat, since disowning would
    # be confusing when hat use is logged (see issue #1979)
    author.comments.active
      .where(hat_id: nil)
      .or(author.comments.active.joins(:hat).where(hats: {modlog_use: false}))
      .update_all(user_id: inactive_user.id)
    refresh_counts! author
  end

  def self.refresh_counts! user
    user&.refresh_counts!
    inactive_user.refresh_counts!
  end
end
