class TermTaxonomyDecorator < ApplicationDecorator
  include CustomFieldsConcern
  delegate_all

  # return the title for current locale
  def the_title
    r = {title: object.name.translate(@_deco_locale), object: object}
    h.hooks_run("taxonomy_the_title", r) rescue nil # avoid error for command the_url for categories
    r[:title]
  end

  # return the slug for current locale
  def the_slug
    object.slug.translate(@_deco_locale)
  end


  # return the content for current locale + shortcodes executed
  def the_content
    r = {content: object.description.to_s.translate(@_deco_locale), object: object}
    h.hooks_run("taxonomy_the_content", r)
    h.do_shortcode(r[:content], self)
  end

  def the_status
    if status.to_s.to_bool
      "<span class='label label-success'> #{I18n.t('admin.button.actived')} </span>"
    else
      "<span class='label label-default'> #{I18n.t('admin.button.not_actived')} </span>"
    end
  end

  # return excerpt for this post type
  # qty_chars: total or characters maximum
  def the_excerpt(qty_chars = 200)
    r = {content: object.description.to_s.translate(@_deco_locale).strip_tags.gsub(/&#13;|\n/, " ").truncate(qty_chars), object: object}
    h.hooks_run("taxonomy_the_excerpt", r)
    r[:content]
  end

  # ---------------------- filters
  # return all posts for this model (active_record) filtered by permissions + hidden posts + roles + etc...
  # in return object, you can add custom where's or pagination like here:
  # http://edgeguides.rubyonrails.org/active_record_querying.html
  def the_posts
    h.verify_front_visibility(object.posts)
  end

  # search a post with id (integer) or slug (string)
  def the_post(slug_or_id)
    return nil unless slug_or_id.present?
    return object.posts.where(id: slug_or_id).first.decorate rescue nil if slug_or_id.is_a?(Integer)
    return object.posts.find_by_slug(slug_or_id).decorate rescue nil if slug_or_id.is_a?(String)
  end

  # return edit url for current taxonomy: PostType, PostTag, Category
  def the_edit_url
    link = ""
    case object.class.name
      when "PostType"
        link = h.edit_admin_settings_post_type_url(object)
      when "Category"
        link = h.edit_admin_post_type_category_url(object.post_type.id, object)
      when "PostTag"
        link = h.edit_admin_post_type_post_tag_url(object.post_type.id, object)
      when "Site"
        link = h.admin_settings_site_url
    end
    link
  end

  # cache identifier, the format is: [current-site-prefix]/[object-id]-[object-last_updated]/[current locale]
  # key: additional key for the model
  def cache_prefix(key = "")
    res = ""
    case object.class.name
      when "PostType"
        res = "#{h.current_site.cache_prefix}/ptype#{object.id}#{"/#{key}" if key.present?}"
      when "Category"
        res = "#{h.current_site.cache_prefix}/pcat#{object.id}#{"/#{key}" if key.present?}"
      when "PostTag"
        res = "#{h.current_site.cache_prefix}/ptag#{object.id}#{"/#{key}" if key.present?}"
      when "Site"
        res = "/#{object.id}/#{I18n.locale}#{"/#{key}" if key.present?}"
    end
    res
  end

end